defmodule Game.System.Player do
  @moduledoc """
  Responsible for resuming and suspending a player entity. Basically, unserializes a character out of cold storage
  into the game world.
  """

  use GenServer
  require Logger

  alias Game.Component.{Position, Look, Camera, Name, ItemLook, HPMP}
  alias Game.World

  def resume(client_id, character_id), do: GenServer.call(__MODULE__, {:resume, {client_id, character_id}})
  def suspend(client_id), do: GenServer.call(__MODULE__, {:suspend, {client_id}})

  def start_link(_, _opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_), do: {:ok, %{clients: %{}}}

  defp do_resume(client_id, character_id) do
    World.add_entity(character_id, :player)

    IO.inspect(character_id)
    character = Schema.Character.get(character_id) |> IO.inspect()

    Game.Component.new(:name, character_id, %Name{name: character.name})

    Game.Component.new(:look, character_id, %Look{armor_id: 2})

    Game.Component.new(:position, character_id, %Position{
      instance_id: 0,
      x: character.x,
      y: character.y,
      direction: :north
    })

    Game.Component.new(:hpmp, character_id, %HPMP{level: 1, total_xp: 100, hp: 10000, mp: 20000, max_hp: 10000, max_mp: 20000})
    Game.Component.new(:wallet, character_id, %Game.Component.Wallet{balance: 100_000})

    id = :rand.uniform(9_999_999)
    Game.World.add_entity(id, :item)

    Game.Component.new(:name, id, %Name{name: "Yellow Scroll"})

    Game.Component.new(:look, id, %ItemLook{
      icon_id: 49152 + 246,
      color_id: 6
    })

    id2 = :rand.uniform(9_999_999)
    Game.World.add_entity(id, :item)

    Game.Component.new(:name, id2, %Name{name: "Flameblade"})

    Game.Component.new(:look, id2, %ItemLook{
      icon_id: 49152 + 58,
      color_id: 13
    })

    Game.Component.new(:weapon, id2, %Game.Component.Weapon{
      look_id: 4,
      color_id: 13,
      small_dam: {10, 20},
      large_dam: {10, 20},
      swing_sound: 331
    })

    Game.Component.new(:inventory, character_id, %Game.Component.Inventory{items: %{0 => id, 1 => id2}})

    Game.Component.new(
      :camera,
      character_id,
      %Camera{
        client_id: client_id,
        instance_id: 0,
        x0: character.x - 7,
        y0: character.y - 7,
        x1: character.x + 7,
        y1: character.y + 8
      }
    )
  end

  defp do_suspend(character_id) do
    position = Game.Component.lookup(:position, character_id)
    Schema.Character.update(character_id, position)

    World.delete_entity(character_id)
  end

  defp unmonitor_by_pid(pid, clients) do
    {ref, _client_id, entity_id} = Map.get(clients, pid)
    Process.demonitor(ref)

    {Map.delete(clients, ref), entity_id}
  end

  def handle_call({:resume, {client_id, entity_id}}, {from_pid, _}, state) do
    Logger.debug("[Player] Client Registered")

    ref = Process.monitor(from_pid)
    clients = Map.put(state.clients, from_pid, {ref, client_id, entity_id})

    do_resume(client_id, entity_id)

    {:reply, :ok, %{state | clients: clients}}
  end

  def handle_call({:suspend, _client_id}, {from_pid, _}, state) do
    Logger.debug("[Player] Client Unregistered")

    {clients, entity_id} = unmonitor_by_pid(from_pid, state.clients)
    do_suspend(entity_id)

    {:reply, :ok, %{state | clients: clients}}
  end

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.debug("[Player] Client Crashed with #{reason}, Removing")

    {clients, entity_id} = unmonitor_by_pid(pid, state.clients)
    do_suspend(entity_id)

    {:noreply, %{state | clients: clients}}
  end
end
