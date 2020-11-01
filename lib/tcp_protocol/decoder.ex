defmodule TCPProtocol.Decoder.Macros do
  defmacro str(name) do
    quote do
      <<len::8, unquote(name)::size(len)-bytes>>
    end
  end
end

defmodule TCPProtocol.Decoder do
  alias TCPProtocol.Crypt
  require Logger
  import TkServer.Commands
  import TCPProtocol.Decoder.Macros

  def from_bytes(<<0xAA, len::16, data::size(len)-bytes>>, stream_key) do
    data |> decrypt(stream_key) |> parse()
  end

  def decrypt(<<op::8, _::binary>> = data, stream_key) do
    case op do
      0x00 -> data
      0x03 -> decrypt_static(data)
      0x10 -> data
      0x62 -> data
      0x72 -> data
      0x43 -> decrypt_static(data)
      0x3A -> decrypt_static(data)
      _ -> decrypt_stream(data, stream_key)
    end
  end

  def decrypt_static(<<op::8, seq::8, data::binary>>), do: <<op, seq, Crypt.static_key(data, seq)::binary>>

  def decrypt_stream(<<op::8, seq::8, data::binary>>, key),
    do: <<op, seq, Crypt.stream_key(data, seq, key, :trailer)::binary>>

  def parse(<<0x03, _::8, str(name), str(password), _::binary>>), do: input_auth(name: name, password: password)
  def parse(<<0x04, _::binary>>), do: input_create_character()
  def parse(<<0x26, _::binary>>), do: input_change_password()

  def parse(<<0x11, _::8, direction::8, _::binary>>), do: input_direction(direction: decode(:direction, direction))

  def parse(<<0x32, _::8, direction::8, order::8, speed::8, x::16, y::16, _::binary>>),
    do: input_move(x: x, y: y, direction: decode(:direction, direction), order: order, speed: speed)

  def parse(
        <<0x06, _::8, direction::8, order::8, speed::8, x::16, y::16, x0::16, y0::16, x1::8, y1::8, crc::16, _::binary>>
      ) do
    input_move_with_map(
      x: x,
      y: y,
      direction: decode(:direction, direction),
      speed: speed,
      order: order,
      x0: x0,
      y0: y0,
      x1: x1,
      y1: y1,
      crc: crc
    )
  end

  def parse(<<0x82, _::binary>>), do: input_move_camera()

  def parse(<<0x07, _::8, type::8, _::binary>>), do: input_pickup(type: decode(:pickup_type, type))
  def parse(<<0x08, _::8, position::8, all::8, _::binary>>), do: input_drop(position: position, all: decode(:bool, all))
  def parse(<<0x24, _::8, amount::32, _::binary>>), do: input_drop_money(amount: amount)
  def parse(<<0x29, _::8, position::8, all::8, _::binary>>), do: input_give(position: position, all: decode(:bool, all))
  def parse(<<0x2A, _::8, amount::32, _::binary>>), do: input_give_money(amount: amount)
  def parse(<<0x09, _::binary>>), do: input_look()
  def parse(<<0x12, _::8, position::8, _::binary>>), do: input_wield(position: position)
  def parse(<<0x13, _::8, _::binary>>), do: input_swing()

  # Input cast is a bit annoying. It is the same packet type for self, prompt, or target-able spells. You have to infer
  # the type based on the shape. Addt'l, the prompt doesn't tell us the size of the answer, so it's annoying to read but
  # appears the 0x000F signifies the end of the data.

  # TODO: This causes isseus because we can't really tell between an exactly 8 byte long answer frame and a
  # target frame. It currently abuses that there aren't any maps with a y > 255 to use the leading 0x00 to
  # determine between the two.
  def parse(<<0x0F, _::8, position::8, 0x000F::16, _::size(56)>>), do: input_cast(position: position)

  def parse(<<0x0F, _::8, position::8, target::32, x::16, 0x00::8, y::8, 0x0000F::16, _::binary>>) do
    input_cast(position: position, target: target, x: x, y: y)
  end

  def parse(<<0x0F, _::8, position::8, answer::binary>>) do
    [answer | _] = :binary.split(answer, <<0x0000F::16>>)
    input_cast(position: position, answer: answer)
  end

  def parse(<<0x17, _::8, confirm::8, position::8, _::binary>>),
    do: input_throw(position: position, confirm: decode(:bool, confirm))

  def parse(<<0x1A, _::8, position::8, _::binary>>), do: input_eat(position: position)
  def parse(<<0x1C, _::8, position::8, _::binary>>), do: input_use(position: position)
  def parse(<<0x1D, _::8, emote::8, _::binary>>), do: input_emote(emote: decode(:emote, emote))
  def parse(<<0x1E, _::binary>>), do: input_equip()
  def parse(<<0x1F, _::8, type::8, _::binary>>), do: input_unequip(type: decode(:equip_type, type))
  def parse(<<0x20, _::binary>>), do: input_opendoor()

  def parse(<<0x0E, _::8, type::8, str(message), _::binary>>),
    do: input_message(type: decode(:chat_type, type), message: message)

  def parse(<<0x19, _::8, str(name), str(message), _::binary>>), do: input_whisper(name: name, message: message)

  def parse(<<0x34, _::8, position::8, _::binary>>), do: input_post(position: position)

  def parse(<<0x30, _::8, type::8, old_position::8, new_position::8, _::binary>>),
    do: input_rearrange(type: decode(:rearrange_type, type), old_position: old_position, new_position: new_position)

  def parse(<<0x1B, _::binary>>), do: input_change_status()
  def parse(<<0x0D, _::binary>>), do: input_ignore()
  def parse(<<0x77, _::binary>>), do: input_friends()
  def parse(<<0x2E, _::8, str(name), _::binary>>), do: input_group_member(name: name)

  def parse(<<0x43, _::8, _order::8, entity_id::32, _::binary>>), do: input_click_entity(entity_id: entity_id)
  def parse(<<0x85, _::binary>>), do: input_click_hunter()

  def parse(<<0x39, _::binary>>), do: input_menu()

  def parse(<<0x3A, _::8, pane_id::8, menu_id::32, action::8, a::binary>>) do
    IO.inspect(a)
    input_wizard(pane_id: pane_id, menu_id: menu_id, action: action)
  end

  def parse(<<0x05, _::8, x0::16, y0::16, x1::8, y1::8, crc::16, _::binary>>),
    do: request_map_tiles(x0: x0, y0: y0, x1: x1, y1: y1, crc: crc)

  def parse(<<0x41, _::binary>>), do: request_parcel()
  def parse(<<0x7B, _::binary>>), do: request_meta()
  def parse(<<0x0C, _::8, entity_id::32, _::binary>>), do: request_missing_object(entity_id: entity_id)
  def parse(<<0x2D, _::binary>>), do: request_status()
  def parse(<<0x38, _::binary>>), do: request_resync()
  def parse(<<0x18, _::binary>>), do: request_userlist()
  def parse(<<0x27, _::binary>>), do: request_quest()
  def parse(<<0x3B, _::8, sub_op::8, _::binary>>), do: request_boards(sub_op: sub_op)
  def parse(<<0x4A, _::binary>>), do: request_exchange()
  def parse(<<0x4C, _::binary>>), do: request_powerboards()
  def parse(<<0x6B, _::binary>>), do: request_creation()
  def parse(<<0x73, _::binary>>), do: request_webboard()
  def parse(<<0x7C, _::binary>>), do: request_minimap()
  def parse(<<0x7D, _::binary>>), do: request_ranking()
  def parse(<<0x84, _::binary>>), do: request_hunterlist()
  def parse(<<0x66, _::binary>>), do: request_towns()

  def parse(<<0x00, version::16, _::8, deep::16>>), do: client_version(version: version, deep: deep)
  def parse(<<0x10, str(token), str(name), id::32, _::binary>>), do: client_resume(token: token, name: name, id: id)
  def parse(<<0x0B, _::binary>>), do: client_end_session()
  def parse(<<0x60, _::binary>>), do: client_ping()
  def parse(<<0x62, _::binary>>), do: client_baram()
  def parse(<<0x71, _::binary>>), do: client_keepalive()

  def parse(<<opcode::8, data::binary>>) do
    Logger.warn("Unknown Opcode: #{inspect(opcode)} #{inspect(data)}")
    :unknown
  end

  defp decode(:direction, 0x00), do: :north
  defp decode(:direction, 0x01), do: :east
  defp decode(:direction, 0x02), do: :south
  defp decode(:direction, 0x03), do: :west

  defp decode(:chat_type, 0x00), do: :normal
  defp decode(:chat_type, 0x01), do: :yell

  defp decode(:pickup_type, 0x00), do: :single
  defp decode(:pickup_type, 0x01), do: :stack
  defp decode(:pickup_type, 0x03), do: :area

  defp decode(:equip_type, 0x01), do: :weapon
  defp decode(:equip_type, 0x02), do: :armor
  defp decode(:equip_type, 0x03), do: :shield
  defp decode(:equip_type, 0x04), do: :helmet
  defp decode(:equip_type, 0x06), do: :necklace
  defp decode(:equip_type, 0x07), do: :hand_left
  defp decode(:equip_type, 0x08), do: :hand_right
  defp decode(:equip_type, 0x0D), do: :boots
  defp decode(:equip_type, 0x0E), do: :cape
  defp decode(:equip_type, 0x11), do: :coat
  defp decode(:equip_type, 0x14), do: :accessory_left
  defp decode(:equip_type, 0x15), do: :accessory_right
  defp decode(:equip_type, 0x16), do: :mask
  defp decode(:equip_type, 0x17), do: :crown

  defp decode(:emote, 0x00), do: :laugh
  defp decode(:emote, 0x01), do: :cry
  defp decode(:emote, 0x02), do: :shame
  defp decode(:emote, 0x03), do: :heart
  defp decode(:emote, 0x04), do: :boring
  defp decode(:emote, 0x05), do: :sleep
  defp decode(:emote, 0x06), do: :gasp
  defp decode(:emote, 0x07), do: :rage
  defp decode(:emote, 0x08), do: :sarcasm
  defp decode(:emote, 0x09), do: :shrug
  defp decode(:emote, 0x0A), do: :annoyed
  defp decode(:emote, 0x0B), do: :dance
  defp decode(:emote, 0x0C), do: :bow
  defp decode(:emote, 0x0D), do: :triumph
  defp decode(:emote, 0xFE), do: :strange
  defp decode(:emote, 0xFF), do: :kiss

  defp decode(:rearrange_type, 0x00), do: :inventory
  defp decode(:rearrange_type, 0x01), do: :spell_book

  defp decode(:bool, 0), do: false
  defp decode(:bool, _), do: true
end
