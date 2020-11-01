defmodule TkServer.Commands do
  import Record

  # Connection (Server -> Client)

  defrecord(:init_transfer, addr: {0, 0, 0, 0}, port: 0, token: nil, name: nil, id: nil)
  defrecord(:ack_transfer, unused: nil)
  defrecord(:set_auth_status, auth: false, message: "")

  # Client Information (Server -> Client)

  defrecord(:set_player_entity_coords, x: 0, y: 0, camera_x: 0, camera_y: 0)
  defrecord(:set_player_entity_id, entity_id: nil)

  defrecord(:set_player_stats,
    country: nil,
    totem: nil,
    level: 0,
    max_hp: 0,
    max_mp: 0,
    might: 0,
    will: 0,
    grace: 0,
    armor: 0,
    max_inventory_slots: 0,
    hp: 0,
    mp: 0,
    xp: 0,
    xp_percent: 0,
    coins: 0,
    drunk: false,
    blind: false,
    flags: 0,
    settings: 0
  )

  # Camera Rendering (Server -> Client)

  defrecord(:set_map, id: 0, width: 0, height: 0, title: "", lighting: 0)
  defrecord(:set_map_tiles, x: 0, y: 0, to_x: 0, to_y: 0, tiles: nil)

  defrecord(:set_entity_direction, entity_id: nil, direction: nil)
  defrecord(:set_entity_chat, entity_id: nil, type: :normal, message: "")
  defrecord(:set_entity_action, entity_id: nil, type: :none, speed: 0)
  defrecord(:add_broadcast, type: :whisper, message: "")

  defrecord(:move_entity_position, entity_id: nil, x: 0, y: 0, direction: nil)
  defrecord(:move_player_entity_and_camera_position, x: 0, y: 0, direction: nil, camera_x: 0, camera_y: 0)
  defrecord(:edge_move_player_entity_and_camera_position, x: 0, y: 0, direction: nil, camera_x: 0, camera_y: 0)

  defrecord(:add_entity,
    entity_id: nil,
    name: "",
    x: 0,
    y: 0,
    direction: nil,
    armor_id: 0,
    armor_color_id: 0,
    weapon_id: 0,
    weapon_color_id: 0
  )

  defrecord(:update_entity, entity_id: nil, name: "", armor_id: 0, armor_color_id: 0, weapon_id: 0, weapon_color_id: 0)
  defrecord(:remove_entity, entity_id: nil)
  defrecord(:remove_mob, entity_id: nil)

  defrecord(:add_floor_object, object_id: nil, x: 0, y: 0, item_id: 0, color_id: 0)
  defrecord(:add_npc_entity, entity_id: nil, x: 0, y: 0, direction: :south, look_id: 0, color_id: 0)

  defrecord(:add_animation, entity_id: nil, animation_id: 0, loops: 0, x: nil, y: nil)
  defrecord(:add_sound, entity_id: nil, sound_id: 0)

  defrecord(:update_entity_health_bar, entity_id: nil, percent: 0, amount: 0)

  # Sidebar Rendering

  defrecord(:set_timer, name: "", duration: 0)
  defrecord(:set_spell_timer, position: 0, duration: 0)

  defrecord(:add_spellbook_spell, position: 0, type: 0, name: "", prompt: "")
  defrecord(:remove_spellbook_spell, position: 0)

  defrecord(:add_inventory_item,
    position: 0,
    icon_id: 0,
    icon_color_id: 0,
    name: "",
    description: "",
    amount: 0,
    type: 0,
    durability: 0,
    protected: 0,
    owner_name: ""
  )

  defrecord(:remove_inventory_item, position: 0, remove_item_type: 0)

  defrecord(:set_refresh, unused: nil)

  # Board Rendering

  defrecord(:set_board_index, title: "", boards: [])

  # Menu Rendering

  defrecord(:set_wizard_text, message: "", graphic_id: nil, color_id: nil)

  # Client Player Input (Client -> Server)

  defrecord(:input_auth, name: nil, password: nil)
  defrecord(:input_create_character, unused: nil)
  defrecord(:input_change_password, unused: nil)

  defrecord(:input_direction, direction: nil)
  defrecord(:input_move, x: 0, y: 0, direction: nil, speed: 0, order: 0)
  defrecord(:input_move_with_map, x: 0, y: 0, direction: nil, speed: 0, order: 0, x0: 0, y0: 0, x1: 0, y1: 0, crc: 0)
  defrecord(:input_move_camera, unused: nil)

  defrecord(:input_pickup, type: :single)

  defrecord(:input_drop, position: 0, all: false)
  defrecord(:input_drop_money, amount: 0)

  defrecord(:input_give, position: 0, all: false)
  defrecord(:input_give_money, amount: 0)

  defrecord(:input_look, unused: nil)
  defrecord(:input_cast, position: 0, answer: nil, target: nil, x: nil, y: nil)
  defrecord(:input_wield, position: 0)
  defrecord(:input_swing, unused: nil)
  defrecord(:input_throw, position: 0, confirm: false)
  defrecord(:input_eat, position: 0)
  defrecord(:input_use, position: 0)
  defrecord(:input_emote, emote: nil)
  defrecord(:input_equip, unused: nil)
  defrecord(:input_unequip, type: nil)
  defrecord(:input_opendoor, unused: nil)

  defrecord(:input_message, type: :normal, message: nil)
  defrecord(:input_whisper, name: nil, message: nil)
  defrecord(:input_post, position: 0)

  defrecord(:input_rearrange, type: 0, old_position: 0, new_position: 0)

  defrecord(:input_change_status, unused: nil)
  defrecord(:input_ignore, unused: nil)
  defrecord(:input_friends, unused: nil)
  defrecord(:input_group_member, name: "")

  defrecord(:input_click_entity, entity_id: nil)
  defrecord(:input_click_hunter, unused: nil)

  defrecord(:input_menu, unused: nil)
  defrecord(:input_wizard, pane_id: 0, menu_id: 0, action: 0)

  # Client Rendering (Client -> Server)

  defrecord(:request_map_tiles, x0: 0, y0: 0, x1: 0, y1: 0, crc: 0)
  defrecord(:request_parcel, unused: nil)
  defrecord(:request_meta, unused: nil)
  defrecord(:request_missing_object, entity_id: nil)
  defrecord(:request_status, unused: nil)
  defrecord(:request_resync, unused: nil)
  defrecord(:request_userlist, unused: nil)
  defrecord(:request_quest, unused: nil)
  defrecord(:request_boards, sub_op: 0x00)
  defrecord(:request_exchange, unused: nil)
  defrecord(:request_powerboards, unused: nil)
  defrecord(:request_creation, unused: nil)
  defrecord(:request_webboard, unused: nil)
  defrecord(:request_minimap, unused: nil)
  defrecord(:request_ranking, unused: nil)
  defrecord(:request_hunterlist, unused: nil)
  defrecord(:request_towns, unused: nil)

  # Client Unsolicited (Client -> Server)

  defrecord(:client_resume, token: nil, name: nil, id: 0)
  defrecord(:client_end_session, unused: nil)
  defrecord(:client_ping, unused: nil)

  defrecord(:client_version, version: 0, deep: nil)
  defrecord(:client_keepalive, unused: nil)
  defrecord(:client_baram, unused: nil)
end
