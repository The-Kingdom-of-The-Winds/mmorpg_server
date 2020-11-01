defmodule Game.World do
  use GenServer

  alias Game.Component
  alias Game.Component.TileWarp

  @tick_interval 50

  @initial_state %{
    entities: %{},
    tick: 0,
    last_tick_ms: 0
  }

  def add_entity(entity_id, type), do: GenServer.cast(__MODULE__, {:add_entity, {entity_id, type}})
  def delete_entity(entity_id), do: GenServer.cast(__MODULE__, {:delete_entity, {entity_id}})
  def debug_state(), do: GenServer.call(__MODULE__, {:debug_state})

  def start_link(_, _opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_) do
    Component.init(:talking)
    Component.init(:whisper)
    Component.init(:name)
    Component.init(:look)
    Component.init(:action)
    Component.init(:transform_position)
    Component.init(:position)
    Component.init(:camera)
    Component.init(:hpmp)
    Component.init(:item_look)
    Component.init(:pickupable)
    Component.init(:wallet)
    Component.init(:broadcast)
    Component.init(:tile_warp)
    Component.init(:damage_entity)
    Component.init(:sound, :bag)
    Component.init(:animation, :bag)
    Component.init(:bounding_box)
    Component.init(:mob_template)
    Component.init(:killable)
    Component.init(:inventory)
    Component.init(:gold)
    Component.init(:equiptment)
    Component.init(:weapon)

    Component.init(:spawner)
    Component.init(:spawned, :bag)

    Component.new(:position, 1234, %Game.Component.Position{instance_id: 0, x: 3, y: 3, direction: :east})
    Component.new(:name, 1234, %Game.Component.Name{name: "Jadespear"})
    Component.new(:look, 1234, %Game.Component.MobLook{graphic_id: 32768 + 16, color_id: 15})

    # New Squirrel Spawner
    # 555
    # 0, 180, 100
    # 0, 200, 120

    alias Game.Component.{HPMP, MobLook}

    Component.new(:mob_template, 554, %{
      hpmp: %HPMP{max_hp: 1000, hp: 1000},
      look: %MobLook{graphic_id: 32768 + 25, color_id: 9}
    })

    Component.new(:bounding_box, 555, %{room_id: 0, x0: 180, y0: 100, x1: 200, y1: 120})
    Component.new(:spawner, 555, %{mob_template: 554, mob_limit: 25})

    data = File.read!("./warps.csv")

    String.split(data, "\n")
    |> IO.inspect()
    |> Enum.map(fn line ->
      data = String.split(line, ",")

      {from_i, from_x, from_y, to, to_x, to_y} =
        case data do
          [_, from_i, from_x, from_y, to, to_x, to_y] -> {from_i, from_x, from_y, to, to_x, to_y}
          [from_i, from_x, from_y, to, to_x, to_y] -> {from_i, from_x, from_y, to, to_x, to_y}
        end

      Component.new(
        :tile_warp,
        {String.to_integer(from_i), String.to_integer(from_x), String.to_integer(from_y)},
        %TileWarp{instance_id: String.to_integer(to), x: String.to_integer(to_x), y: String.to_integer(to_y)}
      )
    end)

    Process.send_after(self(), :tick, @tick_interval)
    {:ok, @initial_state}
  end

  def handle_cast({:add_entity, {entity_id, _type}}, state) do
    state = put_in(state[:entities][entity_id], System.monotonic_time())
    {:noreply, state}
  end

  def handle_cast({:delete_entity, {entity_id}}, state) do
    entities = Map.delete(state.entities, entity_id)

    [:talking, :whisper, :name, :look, :action, :position, :camera, :hpmp, :spawned, :killable]
    |> Enum.each(fn c -> :ets.delete(c, entity_id) end)

    {:noreply, %{state | entities: entities}}
  end

  def handle_call({:debug_state}, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:tick, state) do
    tick = state.tick + 1
    start = System.monotonic_time(:microsecond)
    run_systems(tick)
    total = System.monotonic_time(:microsecond) - start

    Process.send_after(self(), :tick, @tick_interval)

    {:noreply, %{state | tick: tick, last_tick_ms: total}}
  end

  def run_systems(tick) do
    Game.System.TransformPosition.tick(tick)
    Game.System.Portal.tick(tick)
    Game.System.Input.tick(tick)
    Game.System.Spawner.tick(tick)
    Game.System.CameraRender.tick(tick)
    Game.System.SidebarRender.tick()

    :ets.delete_all_objects(:broadcast)
    :ets.delete_all_objects(:talking)
    :ets.delete_all_objects(:action)
    :ets.delete_all_objects(:sound)
    :ets.delete_all_objects(:animation)
    :ets.delete_all_objects(:damage_entity)
  end
end
