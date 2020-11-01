defmodule TCPProtocol.Encoder do
  alias TCPProtocol.Crypt
  require Logger
  import TkServer.Commands

  def from_msg(msg, seq, nil), do: encode(msg) |> encrypt(seq, nil) |> frame()
  def from_msg(msg, seq, key), do: encode(msg) |> encrypt(seq, key) |> frame()

  def encrypt({0x03, data}, _seq, _key), do: <<0x03::8, data::binary>>
  def encrypt({0x22, data}, seq, _key), do: <<0x22::8, seq::8, data::binary>>
  def encrypt({0x02, data}, seq, _key), do: <<0x02::8, seq::8, Crypt.static_key(data, seq)::binary>>
  def encrypt({0x0A, data}, seq, _key), do: <<0x0A::8, seq::8, Crypt.static_key(data, seq)::binary>>

  def encrypt({op, data}, seq, nil), do: <<op::8, seq::8, Crypt.static_key(data, seq)::binary>>
  def encrypt({op, data}, seq, key), do: <<op::8, seq::8, Crypt.stream_key(data, seq, key, nil)::binary>>

  def frame(<<data::binary>>), do: <<0xAA, IO.iodata_length(data)::16, data::binary>>

  def encode(set_auth_status(auth: false, message: message)), do: {0x02, <<0xFF, encode(message)::binary, 0x00::24>>}
  def encode(set_auth_status(auth: true)), do: {0x02, <<0x00::48>>}

  def encode(init_transfer(addr: addr, port: port, token: token, name: name, id: id)) do
    {0x03, <<encode(addr)::binary, port::16, encode(<<encode(token)::binary, encode(name)::binary, id::32>>)::binary>>}
  end

  def encode(set_refresh()), do: {0x22, <<0xFA, 0xF6, 0xC1, 0x00>>}

  def encode(set_player_entity_coords(x: x, y: y, camera_x: camera_x, camera_y: camera_y)),
    do: {0x04, <<x::16, y::16, camera_x::16, camera_y::16>>}

  def encode(set_player_entity_id(entity_id: entity_id)), do: {0x05, <<entity_id::32, 0x00::56>>}

  def encode(set_entity_action(entity_id: entity_id, type: type, speed: speed)),
    do: {0x1A, <<entity_id::32, encode(:action_type, type)::8, 0x00, speed, 0x00>>}

  def encode(set_map_tiles(x: x, y: y, to_x: to_x, to_y: to_y, tiles: tiles)),
    do: {0x06, [<<0x00, x::16, y::16, to_x::8, to_y::8>>, tiles] |> IO.iodata_to_binary()}

  def encode(set_map(id: id, width: w, height: h, title: title, lighting: lighting)),
    do: {0x15, <<id::16, w::16, h::16, 0x00::16, encode(title)::binary, lighting::16>>}

  def encode(add_broadcast(type: type, message: message)),
    do: {0x0A, <<encode(:message_type, type)::8, 0x00, encode(message)::binary, 0x00::24>>}

  def encode(move_entity_position(entity_id: entity_id, x: x, y: y, direction: direction)),
    do: {0x0C, <<entity_id::32, x::16, y::16, encode(:direction, direction)::8, 0x00>>}

  def encode(remove_entity(entity_id: entity_id)), do: {0x0E, <<entity_id::32, 0x00>>}

  def encode(remove_mob(entity_id: entity_id)), do: {0x5F, <<entity_id::32, 0x00>>}

  def encode(set_entity_chat(entity_id: entity_id, type: type, message: message)),
    do: {0x0D, <<encode(:chat_type, type)::8, entity_id::32, encode(message)::binary, 0x00, 0x00>>}

  def encode(
        edge_move_player_entity_and_camera_position(
          x: x,
          y: y,
          direction: direction,
          camera_x: camera_x,
          camera_y: camera_y
        )
      ) do
    {0x0B, <<encode(:direction, direction)::8, x::16, y::16, camera_x::16, camera_y::16, 0x00>>}
  end

  def encode(set_entity_direction(entity_id: player_id, direction: dir)),
    do: {0x11, <<player_id::32, encode(:direction, dir)::8>>}

  def encode(
        move_player_entity_and_camera_position(x: x, y: y, direction: direction, camera_x: camera_x, camera_y: camera_y)
      ),
      do: {0x0B, <<encode(:direction, direction)::8, x::16, y::16, camera_x::16, camera_y::16, 0x00>>}

  def encode(add_floor_object(object_id: object_id, x: x, y: y, item_id: item_id, color_id: color_id)) do
    {0x07, <<0x01::16, x::16, y::16, 0x02::8, object_id::32, item_id::16, color_id::16, 0x00::24>>}
  end

  def encode(
        add_npc_entity(entity_id: entity_id, x: x, y: y, direction: direction, look_id: look_id, color_id: color_id)
      ) do
    {0x07,
     <<0x01::16, x::16, y::16, 0x0C::8, entity_id::32, look_id::16, color_id::8, encode(:direction, direction)::8,
       0x00::24>>}
  end

  def encode(update_entity_health_bar(entity_id: entity_id, percent: percent, amount: amount)) do
    {0x13, <<entity_id::32, 0::8, percent::8, amount::32>>}
  end

  def encode(add_spellbook_spell(position: position, type: type, name: name, prompt: prompt)) do
    {0x17, <<position::8, encode(:spell_type, type)::8, encode(name)::binary, encode(prompt)::binary>>}
  end

  def encode(remove_spellbook_spell(position: position)) do
    {0x18, <<position::8>>}
  end

  def encode(
        add_inventory_item(
          position: position,
          icon_id: icon_id,
          icon_color_id: icon_color_id,
          name: name,
          description: description,
          amount: amount,
          type: type,
          durability: durability,
          protected: protected,
          owner_name: owner_name
        )
      ) do
    {0x0F,
     <<position::8, icon_id::16, icon_color_id::8, encode(description)::binary, encode(name)::binary, amount::32,
       type::8, durability::32, protected::8, encode(owner_name)::binary, 0::8, 0::8>>}
  end

  def encode(remove_inventory_item(position: position, remove_item_type: remove_item_type)),
    do: {0x10, <<position::8, encode(:remove_item_type, remove_item_type)::8>>}

  def encode(set_timer(name: name, duration: duration)) do
    {0x3A, <<encode(name)::binary, duration::32>>}
  end

  def encode(set_spell_timer(position: position, duration: duration)) do
    {0x3F, <<position::16, duration::32>>}
  end

  def encode(add_animation(entity_id: entity_id, animation_id: animation_id, loops: loops, x: nil, y: nil)) do
    {0x29, <<entity_id::32, animation_id::16, loops::16>>}
  end

  def encode(add_animation(animation_id: animation_id, loops: loops, x: x, y: y)) do
    {0x29, <<0::32, animation_id::16, loops::16, x::16, y::16>>}
  end

  def encode(add_sound(entity_id: entity_id, sound_id: sound_id)) do
    {0x19, <<3::16, sound_id::16, 100::8, 4::16, entity_id::32, 1::8, 0::8, 2::8, 2::8, 4::16, 0::8>>}
  end

  def encode(
        add_entity(
          entity_id: entity_id,
          name: name,
          x: x,
          y: y,
          direction: direction,
          armor_id: armor_id,
          armor_color_id: armor_color_id,
          weapon_id: weapon_id,
          weapon_color_id: weapon_color_id
        )
      ) do
    # bytes = <<x::16, y::16, encode(:direction, direction)::8, entity_id::32, 0x010F::16, 0x04, 0x810001::24>>

    bytes = <<x::16, y::16, encode(:direction, direction)::8, entity_id::32, 0x0000::16, 0x00, 0x0000020::24>>

    bytes =
      bytes <>
        <<0x00>> <>
        <<0xCA>> <>
        <<19>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<armor_id::16>> <>
        <<armor_color_id::8>> <>
        <<weapon_id::16>> <>
        <<weapon_color_id::8>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x0000::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0x0000::16>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x80>>

    bytes = bytes <> <<0x00>> <> encode(name) <> <<0x00>>

    {0x33, bytes}
  end

  def encode(
        update_entity(
          entity_id: entity_id,
          name: name,
          armor_id: armor_id,
          armor_color_id: armor_color_id,
          weapon_id: weapon_id,
          weapon_color_id: weapon_color_id
        )
      ) do
    bytes = <<entity_id::32, 0x0000::16, 0x00, 0x000032::24>>
    IO.inspect("HEREEEEEE")

    bytes =
      bytes <>
        <<0x00>> <>
        <<0xCB>> <>
        <<19>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<armor_id::16>> <>
        <<armor_color_id::8>> <>
        <<weapon_id::16>> <>
        <<weapon_color_id::8>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x0000::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0xFFFF::16>> <>
        <<0x00>> <>
        <<0x0000::16>> <>
        <<0x00>> <>
        <<0x00>> <>
        <<0x80>>

    bytes = bytes <> <<0x00>> <> encode(name) <> <<0x00>>

    {0x1D, bytes}
  end

  def encode(
        set_player_stats(
          level: level,
          max_hp: max_hp,
          max_mp: max_mp,
          hp: hp,
          mp: mp,
          coins: coins,
          xp: xp,
          xp_percent: xp_percent
        )
      ) do
    bytes =
      <<0x78000000::32>> <>
        <<0x00::8>> <>
        <<level::8>> <>
        <<max_hp::32>> <>
        <<max_mp::32>> <>
        <<0x10200303::32>> <>
        <<0x20000010::32>> <>
        <<0x00000020::32>> <>
        <<0x00000020::32>> <>
        <<hp::32>> <>
        <<mp::32>> <>
        <<xp::32>> <>
        <<coins::32>> <>
        <<xp_percent::8>> <>
        <<0x00000000::32>> <>
        <<0x00001000::32>> <>
        <<0x111111::24>>

    {0x08, bytes}
  end

  def encode(set_board_index(title: title, boards: boards)) do
    {0x31, <<0x01::8, encode(title)::binary, length(boards)::8, encode(:boards, boards)::binary>>}
  end

  def encode(set_wizard_text(message: message, graphic_id: nil, color_id: nil)) do
    {0x30,
     <<0x00, 0x01, 0xFFFF::32, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
       encode(message, :long)::binary>>}
  end

  def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) when graphic_id >= 49152 do
    {0x30,
     <<0x00, 0x02, 0xFFFF::32, 0x02, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8, 0x01,
       0x00::24, 0x00, 0x00, encode(message, :long)::binary>>}
  end

  # MENU SELECT

  # def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) do
  #   {0x30,
  #    <<0x00, 0x00, 0xFFFF::32, 0x01, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8, 0x01, 0x00,
  #      0x00::16, 0x06, 0x08, encode(message, :long)::binary>>}
  # end

  # SELECT BOX
  # def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) do
  #   {0x30,
  #    <<0x02, 0x00, 0xFFFF::32, 0x01, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8, 0x01, 0x00,
  #      0x00::16, 0x06, 0x08, encode(message, :long)::binary, 0x02, 0x03, "Yes"::binary, 0x02, "No"::binary>>}
  # end

  # MENU SELECT
  # def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) do
  #   {0x2F,
  #    <<0x00, 0x00, 0xFFFF::32, 0x01, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8,
  #      encode(message, :long)::binary, 0x02, 0x03, "Yes"::binary, 0x0001::16, 0x02, "No"::binary, 0x0001::16>>}
  # end

  # MENU INPUT TEXT
  # def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) do
  #   {0x2F,
  #    <<0x02, 0x00, 0xFFFF::32, 0x01, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8,
  #      encode(message, :long)::binary, 0x00::16>>}
  # end

  # MENU BUY ITEM
  # def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) do
  #   {0x2F,
  #    <<0x04, 0x02, 0xFFFF::32, 0x01, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8,
  #      encode(message, :long)::binary, 0x00::16, 0x01::16, 49153::16, 1::8, 0x01::32, encode("Yes")::binary,
  #      encode("Good item")::binary, 0x00>>}
  # end

  # MENU SELL ITEM - SHOWS ITEMS FROM INVENTORY (0x01)
  # def encode(set_wizard_text(message: message, graphic_id: graphic_id, color_id: color_id)) do
  #   {0x2F,
  #    <<0x05, 0x02, 0xFFFF::32, 0x01, 0x01, graphic_id::16, color_id::8, 0x01, graphic_id::16, color_id::8,
  #      encode(message, :long)::binary, 0x00::16, count-> 0x01::8, inv_item->0x01::8>>}
  # end

  def encode(ack_transfer()), do: {0x1E, <<0x00::16>>}

  def encode({a, b, c, d}), do: <<d, c, b, a>>

  def encode(data) when is_binary(data), do: <<IO.iodata_length(data), data::binary>>
  def encode(nil), do: <<0x00, 0x00>>

  defp encode(data, :long) when is_binary(data), do: <<IO.iodata_length(data)::16, data::binary>>
  defp encode(:direction, :north), do: 0x00
  defp encode(:direction, :east), do: 0x01
  defp encode(:direction, :south), do: 0x02
  defp encode(:direction, :west), do: 0x03

  defp encode(:chat_type, :normal), do: 0x00
  defp encode(:chat_type, :yell), do: 0x01

  defp encode(:message_type, :whisper), do: 0x00
  defp encode(:message_type, :status), do: 0x03
  defp encode(:message_type, :system), do: 0x04
  defp encode(:message_type, :popup), do: 0x08
  defp encode(:message_type, :group), do: 0x0B
  defp encode(:message_type, :clan), do: 0x0C

  defp encode(:spell_type, :none), do: 0x00
  defp encode(:spell_type, :prompt), do: 0x01
  defp encode(:spell_type, :target), do: 0x02
  defp encode(:spell_type, :self), do: 0x05

  defp encode(:action_type, :none), do: 0x00
  defp encode(:action_type, :swing), do: 0x01
  defp encode(:action_type, :throw), do: 0x02
  defp encode(:action_type, :shot), do: 0x03
  defp encode(:action_type, :pickup_loud), do: 0x04
  defp encode(:action_type, :pickup), do: 0x05
  defp encode(:action_type, :magic), do: 0x06
  defp encode(:action_type, :eat), do: 0x07
  defp encode(:action_type, :eat_loud), do: 0x08
  defp encode(:action_type, :bow), do: 0x09
  defp encode(:action_type, :triumph), do: 0x0A
  defp encode(:action_type, :laugh), do: 0x0B
  defp encode(:action_type, :cry), do: 0x0C
  defp encode(:action_type, :shame), do: 0x0D
  defp encode(:action_type, :heart), do: 0x0E
  defp encode(:action_type, :boring), do: 0x0F
  defp encode(:action_type, :sleep), do: 0x10
  defp encode(:action_type, :gasp), do: 0x11
  defp encode(:action_type, :rage), do: 0x12
  defp encode(:action_type, :sarcasm), do: 0x13
  defp encode(:action_type, :shrug), do: 0x14
  defp encode(:action_type, :annoyed), do: 0x15
  defp encode(:action_type, :dance), do: 0x16
  defp encode(:action_type, :strange), do: 0x17
  defp encode(:action_type, :kiss), do: 0x18
  defp encode(:action_type, :charge), do: 0x1B
  defp encode(:action_type, :complete), do: 0x1C

  defp encode(:remove_item_type, :remove), do: 0x00
  defp encode(:remove_item_type, :drop), do: 0x01
  defp encode(:remove_item_type, :eat), do: 0x02
  defp encode(:remove_item_type, :smoke), do: 0x03
  defp encode(:remove_item_type, :throw), do: 0x04
  defp encode(:remove_item_type, :shot), do: 0x05
  defp encode(:remove_item_type, :use), do: 0x06
  defp encode(:remove_item_type, :post), do: 0x07
  defp encode(:remove_item_type, :decay), do: 0x08
  defp encode(:remove_item_type, :gave), do: 0x09
  defp encode(:remove_item_type, :sold), do: 0x0A
  defp encode(:remove_item_type, :none), do: 0x0B
  defp encode(:remove_item_type, :broke), do: 0x0C

  defp encode(:boards, [{id, name} | rest]) do
    <<id::16, encode(name)::binary, encode(:boards, rest)::binary>>
  end

  defp encode(:boards, []), do: <<>>
end
