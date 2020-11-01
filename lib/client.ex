defmodule Client do
  alias TkServer.TCPConn
  alias Client.{RenderCamera, RenderStats, RenderBroadcasts, RenderInventory, RenderSpellbook}
  use GenServer
  require Logger
  import TkServer.Commands

  @initial_state %{
    window: :login,
    player_id: nil,
    stream_key: nil,
    client_id: nil,
    scene: %{},
    stats: nil,
    spellbook: nil,
    inventory: nil
  }

  def start_link({client_id}, _opts \\ []) do
    GenServer.start_link(__MODULE__, {client_id}, name: via_tuple(client_id))
  end

  def input(client_id, data) do
    GenServer.cast(via_tuple(client_id), {:input, data})
  end

  def send(client_id, data) do
    GenServer.cast(via_tuple(client_id), {:send, data})
  end

  def render(scene, type, client_id) do
    GenServer.cast(via_tuple(client_id), {:render, type, scene})
  end

  defdelegate send_conn(msg, client_id), to: TCPConn

  def via_tuple(client_id), do: {:via, Registry, {TkServer.ClientRegistry, client_id}}

  def init({client_id}) do
    Logger.info("Client Started for #{client_id}")
    {:ok, %{@initial_state | client_id: client_id}}
  end

  def calculate_camera(x, y, map_width, map_height) do
    camera_x =
      case {x, map_width} do
        _ when x < 8 and map_width >= 16 -> x
        _ when x >= map_width - 8 and map_width >= 16 -> x - map_width + 17
        _ when map_width >= 16 -> 8
        _ when map_width < 16 -> div(16 - map_width, 2) + x
      end

    camera_y =
      case {y, map_height} do
        _ when y < 7 and map_height >= 14 -> y
        _ when y >= map_height - 7 and map_height >= 14 -> y - map_height + 15
        _ when map_height >= 14 -> 7
        _ when map_height < 14 -> div(14 - map_height, 2) + y
      end

    {camera_x, camera_y}
  end

  def transform_scene(scene, %{scene: state_scene, client_id: client_id, player_id: player_id} = state) do
    new = Map.keys(scene)
    old = Map.keys(state_scene)

    render = new -- old

    RenderCamera.derender_entities(MapSet.new(old), MapSet.new(new), player_id) |> send_conn(state.client_id)

    new_pos = scene[player_id][:position]
    %{instance_id: i, x: nx, y: ny} = new_pos

    case state_scene do
      %{^player_id => [{:position, %{instance_id: ^i, x: ^nx, y: ^ny}} | _]} ->
        :noop

      %{^player_id => [{:position, %{instance_id: ^i, x: _x, y: _y}} | _]} ->
        map = String.pad_leading("#{i}", 6, "0")
        IO.inspect(map)
        {:ok, w, h, _} = MapData.load("#{map}.map")
        IO.inspect(w)
        IO.inspect(h)
        # set_map(id: 0, width: w - 1, height: h - 1, title: "Kugnea", lighting: 200) |> send_conn(client_id)

        {camera_x, camera_y} = calculate_camera(new_pos.x, new_pos.y, w, h) |> IO.inspect()

        set_player_entity_coords(
          x: new_pos.x,
          y: new_pos.y,
          camera_x: camera_x,
          camera_y: camera_y
        )
        |> send_conn(client_id)

        # remove_entity(entity_id: player_id) |> send_conn(client_id)
        # set_player_entity_id(entity_id: player_id) |> send_conn(state.client_id)

        # move_entity_position(entity_id: player_id, x: nx, y: ny, direction: new_pos.direction) |> send_conn(client_id)
        pos = scene[player_id][:position]
        look = scene[player_id][:look]

        %{name: name} = scene[player_id][:name]

        add_entity(
          entity_id: player_id,
          name: name,
          x: new_pos.x,
          y: new_pos.y,
          armor_id: look.armor_id,
          armor_color_id: look.armor_color_id,
          weapon_id: look.weapon_id,
          weapon_color_id: look.weapon_color_id,
          direction: pos.direction
        )
        |> send_conn(client_id)

        IO.inspect("add entity")

        set_refresh() |> send_conn(client_id)

      %{} ->
        nil
        IO.inspect("SET MAP")
        map = String.pad_leading("#{i}", 6, "0")
        IO.inspect(map)

        {:ok, w, h, _} = MapData.load("#{map}.map")
        set_map(id: i, width: w - 1, height: h - 1, title: "Kugnea", lighting: 230) |> send_conn(client_id)

        {camera_x, camera_y} = calculate_camera(new_pos.x, new_pos.y, w, h) |> IO.inspect()

        set_player_entity_coords(
          x: new_pos.x,
          y: new_pos.y,
          camera_x: camera_x,
          camera_y: camera_y
        )
        |> send_conn(client_id)

        pos = scene[player_id][:position]
        look = scene[player_id][:look]

        %{name: name} = scene[player_id][:name]

        IO.inspect("add entity")

        add_entity(
          entity_id: player_id,
          name: name,
          x: new_pos.x,
          y: new_pos.y,
          armor_id: look.armor_id,
          armor_color_id: look.armor_color_id,
          weapon_id: look.weapon_id,
          weapon_color_id: look.weapon_color_id,
          direction: pos.direction
        )
        |> send_conn(client_id)
    end

    Enum.each(render, fn entity_id ->
      IO.inspect("render #{entity_id}")

      pos = scene[entity_id][:position]
      look = scene[entity_id][:look]

      case look do
        %Game.Component.Look{} ->
          %{name: name} = scene[entity_id][:name]

          IO.inspect("render entity")

          add_entity(
            entity_id: entity_id,
            name: name,
            x: pos.x,
            y: pos.y,
            armor_id: look.armor_id,
            armor_color_id: look.armor_color_id,
            weapon_id: look.weapon_id,
            weapon_color_id: look.weapon_color_id,
            direction: pos.direction
          )
          |> send_conn(client_id)

        %Game.Component.ItemLook{icon_id: icon_id, color_id: color_id} ->
          add_floor_object(object_id: entity_id, x: pos.x, y: pos.y, item_id: icon_id, color_id: color_id)
          |> send_conn(state.client_id)

        %Game.Component.MobLook{graphic_id: graphic_id, color_id: color_id} ->
          IO.inspect("Rendering mob")

          add_npc_entity(
            entity_id: entity_id,
            x: pos.x,
            y: pos.y,
            direction: pos.direction,
            look_id: graphic_id,
            color_id: color_id
          )
          |> send_conn(state.client_id)
      end
    end)

    existing = new -- render

    transformed_positions =
      Enum.flat_map(existing, fn entity_id ->
        new_pos = scene[entity_id][:transform_position]
        %{x: old_x, y: old_y} = state_scene[entity_id][:position]

        case new_pos do
          [] ->
            []

          # %{direction: ^old_dir, x: ^old_x, y: ^old_y} ->
          #   :noop

          %{direction: dir, x: ^old_x, y: ^old_y} ->
            set_entity_direction(entity_id: entity_id, direction: dir) |> send_conn(client_id)
            [{entity_id, new_pos}]

          %{direction: dir, x: x, y: y} ->
            {old_x, old_y} =
              case dir do
                :north -> {x, y + 1}
                :south -> {x, y - 1}
                :east -> {x - 1, y}
                :west -> {x + 1, y}
              end

            IO.inspect("moving entity #{old_x} #{old_y}")

            if entity_id !== player_id do
              move_entity_position(entity_id: entity_id, x: old_x, y: old_y, direction: dir) |> send_conn(client_id)
            end

            [{entity_id, new_pos}]
        end
      end)
      |> Enum.into(%{})

    Enum.each(existing, fn entity_id ->
      case scene[entity_id][:action] do
        [] ->
          :noop

        %{type: type} ->
          set_entity_action(entity_id: entity_id, type: type, speed: 20) |> send_conn(client_id)
      end

      case scene[entity_id][:damage_entity] do
        [] ->
          :noop

        %{entity_id: entity_id, percent: percent, amount: amount} ->
          update_entity_health_bar(entity_id: entity_id, percent: percent, amount: amount) |> send_conn(client_id)
      end

      case scene[entity_id][:sound] do
        [] ->
          :noop

        %{entity_id: entity_id, sound_id: sound_id} ->
          add_sound(entity_id: entity_id, sound_id: sound_id) |> send_conn(client_id)

        sounds when is_list(sounds) ->
          Enum.each(sounds, fn {_, %{entity_id: entity_id, sound_id: sound_id}} ->
            add_sound(entity_id: entity_id, sound_id: sound_id) |> send_conn(client_id)
          end)
      end

      case scene[entity_id][:animation] do
        [] ->
          :noop

        %{entity_id: entity_id, animation_id: animation_id} ->
          add_animation(entity_id: entity_id, animation_id: animation_id) |> send_conn(client_id)

        animations when is_list(animations) ->
          Enum.each(animations, fn {_, %{entity_id: entity_id, animation_id: animation_id}} ->
            add_animation(entity_id: entity_id, animation_id: animation_id) |> send_conn(client_id)
          end)
      end
    end)

    Enum.each(new, fn entity_id ->
      case scene[entity_id][:talking] do
        [] ->
          :noop

        %{message: message, type: type} ->
          set_entity_chat(entity_id: entity_id, message: message, type: type) |> send_conn(client_id)
      end
    end)

    Enum.each(existing, fn entity_id ->
      old = state_scene[entity_id][:look]

      case scene[entity_id][:look] do
        ^old ->
          :noop

        %Game.Component.MobLook{} = look ->
          remove_entity(entity_id: entity_id) |> send_conn(client_id)

          add_npc_entity(
            entity_id: entity_id,
            x: scene[entity_id][:position].x,
            y: scene[entity_id][:position].y,
            direction: scene[entity_id][:position].direction,
            look_id: look.graphic_id,
            color_id: look.color_id
          )
          |> send_conn(state.client_id)

        %Game.Component.Look{
          armor_id: armor_id,
          armor_color_id: armor_color_id,
          weapon_id: weapon_id,
          weapon_color_id: weapon_color_id
        } ->
          %{name: name} = scene[entity_id][:name]

          update_entity(
            entity_id: entity_id,
            name: name,
            armor_id: armor_id,
            armor_color_id: armor_color_id,
            weapon_id: weapon_id,
            weapon_color_id: weapon_color_id
          )
          |> send_conn(client_id)
      end
    end)

    Enum.map(scene, fn {id, data} ->
      case Map.get(transformed_positions, id) do
        nil ->
          {id, data}

        new_pos ->
          IO.inspect(new_pos)
          {id, update_in(data, [:position], &Map.merge(&1, new_pos))}
      end
    end)
    |> Enum.into(%{})
  end

  def handle_cast({:render, :inventory, inventory}, state) do
    RenderInventory.render(state.inventory, inventory)
    |> send_conn(state.client_id)

    {:noreply, %{state | inventory: inventory}}
  end

  def handle_cast({:render, :spellbook, spellbook}, state) do
    RenderSpellbook.render(state.spellbook, spellbook)
    |> send_conn(state.client_id)

    {:noreply, %{state | spellbook: spellbook}}
  end

  def handle_cast({:render, :stats, stats}, state) do
    RenderStats.render(state.stats, stats) |> send_conn(state.client_id)
    {:noreply, %{state | stats: stats}}
  end

  def handle_cast({:render, :broadcasts, broadcasts}, state) do
    RenderBroadcasts.render(broadcasts) |> send_conn(state.client_id)
    {:noreply, state}
  end

  def handle_cast({:render, :camera, scene}, state) do
    scene = transform_scene(scene, state)
    {:noreply, %{state | scene: scene}}
  end

  @doc """
  Handle logging in
  """
  def handle_cast({:input, input_auth(name: name, password: password)}, %{client_id: client_id} = state) do
    case Registration.Auth.login(name, password) do
      {:ok, player_id} ->
        TCPConn.set_stream_key(client_id, name)

        set_auth_status(auth: true) |> send_conn(client_id)

        init_transfer(addr: {192, 168, 0, 251}, port: 2000, token: "abc123456", name: name, id: player_id)
        |> send_conn(client_id)

        {:noreply, %{state | stream_key: name, player_id: player_id}}

      {:error, _} ->
        set_auth_status(auth: false, message: "Your name or password is incorrect.") |> send_conn(client_id)
        {:noreply, state}
    end
  end

  def handle_cast({:input, client_resume(token: token, name: name, id: id)}, state) do
    Logger.info("Resuming session for #{name}")

    case Registration.Auth.valid_resume?(token, name, id) do
      {:ok} ->
        TCPConn.set_stream_key(state.client_id, name)
        Game.System.Player.resume(state.client_id, id)

        GenServer.cast(Game.System.RenderCamera, {:register, {1, 0, 0, 20, 20}, state.client_id, self()})

        ack_transfer() |> send_conn(state.client_id)
        set_player_entity_id(entity_id: id) |> send_conn(state.client_id)

        {:noreply, %{state | stream_key: name, player_id: id}}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:input, request_map_tiles(x0: x0, y0: y0, x1: x1, y1: y1, crc: crc)}, state) do
    Logger.info("Map request x=#{x0} y=#{y0} to_x=#{x1} to_y=#{y1} checksum=#{crc}")
    id = state[:scene][state.player_id][:position].instance_id |> Integer.to_string()
    map = String.pad_leading("#{id}", 6, "0")

    case {x0, y0, x1, y1} do
      {0, 0, 0, 0} ->
        nil

      _ ->
        tiles = MapData.read_tiles(map, from: {x0, y0 + 1}, to: {x0 + x1, y0 + y1})

        # IO.inspect("Tiles len #{inspect(tiles, limit: 999_999)}")

        # CRC Needs to be calculate from y0 + 1??
        # Something weird happening, we are trimming top row of tiles and far right row
        {:ok, calc_crc} = Map.CRC.calculate(tiles)

        IO.inspect("crc=#{calc_crc}, checksum=#{crc}")

        if calc_crc != crc do
          Logger.info("checksums no matchy")
          set_map_tiles(x: x0, y: y0, to_x: x1, to_y: y1, tiles: tiles) |> send_conn(state.client_id)
        end
    end

    {:noreply, state}
  end

  def handle_cast({:input, input_move(x: x, y: y, direction: direction) = input}, state) do
    Game.System.Input.client_input({state.player_id, input})

    Logger.info("move x=#{x} y=#{y} dir=#{direction}")

    edge_move_player_entity_and_camera_position(x: x, y: y, direction: direction, camera_x: 8, camera_y: 8)
    |> send_conn(state.client_id)

    {:noreply, state}
  end

  def handle_cast(
        {:input,
         input_move_with_map(
           x: x,
           y: y,
           direction: direction,
           x0: x0,
           y0: y0,
           x1: x1,
           y1: y1,
           crc: crc
         )},
        state
      ) do
    Logger.info("move_char_with_map x=#{x} y=#{y} dir=#{direction} dx0=#{x0} dy0=#{y0} dx1=#{x1} dy1=#{y1}")

    # Need to figure out to calculate camera correctly. This crashes up at y=0 now
    # {cx0, cy0, cx1, cy1} =
    case {x0, y0, x1, y1} do
      {0, 0, 0, 0} ->
        # calculate_camera(:north, {max(x - 9, 0), max(y - 11, 0)}) |> IO.inspect()
        Logger.info("Camera is not moving")

      {_, _, _, _} ->
        {cx0, cy0, cx1, cy1} = calculate_camera(direction, {x0, y0})
        Logger.info("Camera is at #{inspect({cx0, cy0, cx1, cy1})}")

        Game.System.Input.client_input({state.player_id, {:client_move_camera, x0: cx0, y0: cy0, x1: cx1, y1: cy1}})
    end

    # {cx0, cy0, cx1, cy1} = calculate_camera(direction, {x0, y0})

    # add_floor_object(object_id: 0x9999, x: x - 1, y: y - 1, item_id: 49155, color_id: 0) |> send_conn(state.client_id)

    # Game.System.Input.client_input({:change_position, state.player_id, direction, x, y})
    # Game.System.CameraRender.move_camera(calculate_camera(direction, {x0, y0}), state.client_id)

    Game.System.Input.client_input({state.player_id, input_move(x: x, y: y, direction: direction)})

    move_player_entity_and_camera_position(x: x, y: y, direction: direction, camera_x: 8, camera_y: 8)
    |> send_conn(state.client_id)

    input(state.client_id, request_map_tiles(x0: x0, y0: y0, x1: x1, y1: y1, crc: crc))

    {:noreply, state}
  end

  def handle_cast({:input, input_direction() = input}, state) do
    Game.System.Input.client_input({state.player_id, input})
    {:noreply, state}
  end

  def handle_cast({:input, input_click_entity()}, state) do
    # set_wizard_text(message: "Hello!", graphic_id: 32768 + 16, color_id: 15) |> send_conn(state.client_id)
    {:noreply, state}
  end

  def handle_cast({:input, client_end_session()}, state) do
    IO.inspect("END SESSION")
    Game.System.Player.suspend(state.client_id)
    {:noreply, @initial_state}
  end

  def handle_cast({:input, input_message() = input}, state) do
    add_animation(entity_id: state.player_id, animation_id: 8, loops: 0) |> send_conn(state.client_id)
    # add_animation(entity_id: 1234, animation_id: 5, loops: 60) |> send_conn(state.client_id)
    # add_sound(entity_id: 1234, sound_id: 5) |> send_conn(state.client_id)

    Game.System.Input.client_input({state.player_id, input})

    {:noreply, state}
  end

  def handle_cast({:input, input_whisper() = input}, state) do
    Game.System.Input.client_input({state.player_id, input})

    # IO.inspect("whisper")
    # set_message(type: :private, message: "Hey what's up") |> send_conn(state.client_id)
    # set_message(type: :status, message: "Status Message") |> send_conn(state.client_id)
    # set_message(type: :system, message: "Hey what's up system") |> send_conn(state.client_id)
    # set_message(type: :group, message: "Hey what's up group") |> send_conn(state.client_id)
    # set_message(type: :clan, message: "Hey what's up clan") |> send_conn(state.client_id)
    # set_message(type: :popup, mes#sage: "Hey what's up popup") |> send_conn(state.client_id)

    {:noreply, state}
  end

  def handle_cast({:input, request_boards()}, state) do
    set_board_index(title: "The Boards", boards: [{0, "Mailbox"}, {1, "Dreamweaver"}]) |> send_conn(state.client_id)
    {:noreply, state}
  end

  def handle_cast({:entity_action, {entity_id, type}}, state) do
    set_entity_action(entity_id: entity_id, type: type, speed: 20) |> send_conn(state.client_id)

    {:noreply, state}
  end

  def handle_cast({:input, input}, state) do
    Logger.info("Received #{inspect(input)} from client")

    Game.System.Input.client_input({state.player_id, input})
    {:noreply, state}
  end

  def handle_cast({:send, set_entity_direction(entity_id: player_id) = command}, state) do
    Logger.info("direction player_id=#{player_id}")

    if player_id !== state.player_id do
      send_conn(command, state.client_id)
    end

    {:noreply, state}
  end

  def handle_cast({:send, command}, %{client_id: client_id} = state) do
    send_conn(command, client_id)
    {:noreply, state}
  end

  def calculate_camera(dir, {dx0, dy0}) do
    case dir do
      :north ->
        # top left
        {dx0, dy0, dx0 + 17, dy0 + 15}

      :west ->
        # top left
        {dx0, dy0, dx0 + 17, dy0 + 15}

      :east ->
        # top right
        {dx0 - 17, dy0, dx0, dy0 + 15}

      :south ->
        # bottom left
        {dx0, dy0 - 15, dx0 + 17, dy0}
    end
  end
end
