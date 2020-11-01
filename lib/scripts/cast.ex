alias Game.Component.{Animation, Action, Sound, DamageEntity, Broadcast}

defmodule Scripts.Cast do
  def on_cast({entity_id, position: position, answer: answer, target: target}) do
    spell_name =
      case position do
        1 -> :gateway
        2 -> :restore
      end

    on_cast({entity_id, spell_name: spell_name, answer: answer, target: target})
  end

  def on_cast({entity_id, spell_name: :gateway, answer: answer, target: nil}) do
    x_rand = :rand.uniform(7)
    y_rand = :rand.uniform(7)

    {x_offset, y_offset, gate} =
      case answer do
        "n" -> {104, 13, "North"}
        "e" -> {201, 105, "East"}
        "w" -> {14, 104, "West"}
        "s" -> {104, 207, "South"}
        _ -> {0, 0, ""}
      end

    x = x_offset + x_rand
    y = y_offset + y_rand

    Broadcast.add_status(entity_id, "You have arrived at #{gate} Gate")

    Game.Component.update(:camera, entity_id, %{instance_id: 0, x0: x - 7, y0: y - 8, x1: x + 7, y1: y + 8})
    Game.Component.update(:position, entity_id, %{instance_id: 0, x: x, y: y})
    Game.Component.new(:sound, entity_id, %Sound{entity_id: entity_id, sound_id: 29})
    Game.Component.new(:animation, entity_id, %Animation{entity_id: entity_id, animation_id: 16})
    Game.Component.new(:action, entity_id, %Action{type: :magic})
  end

  def on_cast({entity_id, spell_name: :restore, answer: nil, target: target}) do
    caster_hpmp = Game.Component.lookup(:hpmp, entity_id)
    mp_cost = 1
    new_mp = caster_hpmp.mp - mp_cost

    case new_mp do
      _ when new_mp >= 0 ->
        Game.Component.update(:hpmp, entity_id, %{caster_hpmp | mp: new_mp})

        hpmp = Game.Component.lookup(:hpmp, target)
        new_hp = min(hpmp.max_hp, hpmp.hp + 1000)
        Game.Component.update(:hpmp, target, %{hpmp | hp: new_hp})

        percent = (new_hp / hpmp.max_hp * 100) |> floor()

        Game.Component.new(:sound, target, %Sound{entity_id: target, sound_id: 5})
        Game.Component.new(:animation, target, %Animation{entity_id: target, animation_id: 5})
        Game.Component.new(:action, entity_id, %Action{type: :magic})

        Game.Component.new(:damage_entity, target, %DamageEntity{entity_id: target, percent: percent, amount: 1000 * -1})

        %{name: name} = Game.Component.lookup(:name, entity_id)

        Broadcast.add_status(target, "#{name} casts Restore on you.")
        Broadcast.add_status(entity_id, "You cast Restore.")

      _ ->
        Broadcast.add_status(entity_id, "You do not have enough mana.")
    end
  end
end
