defmodule Game.System.Input do
  use GenServer
  import TkServer.Commands

  alias Game.Component.{Action, Gold, Position, ItemLook, Name, Wallet}

  def start_link(_, _opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def client_input(input) do
    GenServer.cast(__MODULE__, {:client, input})
  end

  def tick(tick_num) do
    GenServer.call(__MODULE__, {:tick, tick_num})
  end

  def init(_) do
    {:ok, %{input: :queue.new()}}
  end

  def handle_call({:tick, _tick_num}, _from, state) do
    queue = handle_tick(:queue.out(state.input))
    {:reply, :ok, %{state | input: queue}}
  end

  def handle_cast({:client, input}, state) do
    {:noreply, %{state | input: :queue.in(input, state.input)}}
  end

  def handle_tick({{:value, {entity_id, input_direction(direction: direction)}}, queue}) do
    pos = Game.Component.lookup(:position, entity_id)
    Game.Component.new(:transform_position, entity_id, %{direction: direction, x: pos.x, y: pos.y})

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_move(x: x, y: y, direction: direction)}}, queue}) do
    {x, y} =
      case direction do
        :north -> {x, y - 1}
        :south -> {x, y + 1}
        :east -> {x + 1, y}
        :west -> {x - 1, y}
      end

    Game.Component.new(:transform_position, entity_id, %Game.Component.TransformPosition{
      x: x,
      y: y,
      direction: direction
    })

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, {:client_move_camera, x0: x0, y0: y0, x1: x1, y1: y1}}}, queue}) do
    Game.Component.update(:camera, entity_id, %{x0: x0, y0: y0, x1: x1, y1: y1})

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_message(type: type, message: message)}}, queue}) do
    Scripts.Talking.on_talk(entity_id, message, type)
    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {_entity_id, input_whisper(name: to, message: message)}}, queue}) do
    Game.Component.new(:whisper, to, %Game.Component.Message{to: to, message: message})

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_swing()}}, queue}) do
    Scripts.run(&Scripts.Swing.on_swing/1, {entity_id})
    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_emote(emote: emote)}}, queue}) do
    Game.Component.new(:action, entity_id, %Action{type: emote})

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_drop_money(amount: amount)}}, queue}) do
    Game.Component.new(:action, entity_id, %Action{type: :pickup})

    Scripts.DropMoney.on_drop_money(entity_id, amount)

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_drop(position: position, all: false)}}, queue}) do
    player_pos = Game.Component.lookup(:position, entity_id)
    inventory = Game.Component.lookup(:inventory, entity_id)

    item = Map.get(inventory.items, position - 1)

    case item do
      nil ->
        :noop

      item ->
        Game.Component.new(:action, entity_id, %Action{type: :pickup})

        new_inventory = Map.delete(inventory.items, position - 1)

        Game.Component.update(:inventory, entity_id, %{items: new_inventory})

        Game.Component.new(:position, item, %Position{
          instance_id: player_pos.instance_id,
          x: player_pos.x,
          y: player_pos.y
        })

        Game.Component.new(:pickupable, item, %Game.Component.Pickupable{})
    end

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_use(position: position)}}, queue}) do
    inventory = Game.Component.lookup(:inventory, entity_id)

    item = Map.get(inventory.items, position - 1)

    case item do
      nil ->
        :noop

      item ->
        new_inventory = Map.delete(inventory.items, position - 1)
        Game.Component.update(:inventory, entity_id, %{items: new_inventory})

        Game.Component.new(:equiptment, {entity_id, :weapon}, item)

        weapon = Game.Component.lookup(:weapon, item)
        Game.Component.update(:look, entity_id, %{weapon_id: weapon.look_id, weapon_color_id: weapon.color_id})

        Game.Component.new(:pickupable, item, %Game.Component.Pickupable{})
    end

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_unequip(type: type)}}, queue}) do
    equip = Game.Component.lookup(:equiptment, {entity_id, type})

    case equip do
      [] ->
        nil

      equip ->
        :ets.delete(:equiptment, {entity_id, type})
        Game.Component.update(:look, entity_id, %{weapon_id: 0xFFFF})

        inventory = Game.Component.lookup(:inventory, entity_id)

        i =
          Enum.find(0..26, fn i ->
            Map.get(inventory.items, i) == nil
          end)

        new_items = Map.put(inventory.items, i, equip)
        Game.Component.update(:inventory, entity_id, %{items: new_items})
    end

    # case item do
    #   nil ->
    #     :noop

    #   item ->
    #     nil
    #     # new_inventory = Map.delete(inventory.items, position - 1)
    #     # Game.Component.update(:inventory, entity_id, %{items: new_inventory})

    #     # Game.Component.new(:equiptment, entity_id, item)

    #     # Game.Component.update(:look, entity_id, %{weapon_id: 4})

    #     # Game.Component.new(:pickupable, item, %Game.Component.Pickupable{})
    # end

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_look()}}, queue}) do
    Scripts.run(&Scripts.Look.on_look/1, {entity_id})
    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_pickup()}}, queue}) do
    Game.Component.new(:action, entity_id, %Action{type: :pickup})

    player_pos = Game.Component.lookup(:position, entity_id)
    positions = :ets.tab2list(:position)

    items =
      Enum.filter(positions, fn {_, pos} ->
        pos.x == player_pos.x and pos.y == player_pos.y
      end)

    IO.inspect(items)

    case items do
      [] ->
        nil

      [{_entity_id, _player_pos}] ->
        nil

      items ->
        items = items -- [{entity_id, player_pos}]
        [{item_id, _} | _] = items

        pickupable = Game.Component.lookup(:pickupable, item_id)
        gold_amount = Game.Component.lookup(:gold, item_id) |> IO.inspect()

        case {pickupable, gold_amount} do
          {%Game.Component.Pickupable{}, []} ->
            inventory = Game.Component.lookup(:inventory, entity_id)
            :ets.delete(:position, item_id)

            i =
              Enum.find(0..26, fn i ->
                Map.get(inventory.items, i) == nil
              end)

            new_items = Map.put(inventory.items, i, item_id)
            Game.Component.update(:inventory, entity_id, %{items: new_items})

          {%Game.Component.Pickupable{}, %Gold{amount: amount}} ->
            :ets.delete(:gold, item_id)
            :ets.delete(:position, item_id)
            Game.World.delete_entity(item_id)

            %{balance: current_balance} = Game.Component.lookup(:wallet, entity_id)
            Game.Component.update(:wallet, entity_id, %Wallet{balance: current_balance + amount})

          _ ->
            nil
        end
    end

    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input_cast(position: position, answer: answer, target: target)}}, queue}) do
    Scripts.run(&Scripts.Cast.on_cast/1, {entity_id, [position: position, answer: answer, target: target]})
    handle_tick(:queue.out(queue))
  end

  def handle_tick({{:value, {entity_id, input}}, queue}) do
    IO.inspect("Don't have an input handler for #{entity_id} - #{inspect(input)}")

    handle_tick(:queue.out(queue))
  end

  def handle_tick({:empty, queue}), do: queue
end
