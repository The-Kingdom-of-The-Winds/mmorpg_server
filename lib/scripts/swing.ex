defmodule Scripts.Swing do
  alias Game.Component.{Action, DamageEntity, Sound, Position}

  def on_swing({entity_id}) do
    entity_pos = Game.Component.lookup(:position, entity_id)
    Game.Component.new(:action, entity_id, %Action{type: :swing})

    weapon =
      case Game.Component.lookup(:equiptment, {entity_id, :weapon}) do
        [] ->
          %{small_dam: {0, 5}, large_dam: {0, 5}, swing_sound: 331}

        weapon ->
          Game.Component.lookup(:weapon, weapon)
      end

    Game.Component.new(:sound, entity_id, %Sound{entity_id: entity_id, sound_id: weapon.swing_sound})

    target_i = entity_pos.instance_id

    {target_x, target_y} = Position.adjacent(entity_id, :front)

    position = :ets.tab2list(:position)

    Enum.map(position, fn
      {id, %{instance_id: ^target_i, x: ^target_x, y: ^target_y}} ->
        hpmp = Game.Component.lookup(:hpmp, id)

        damage = calculate_swing_damage(entity_id, id)
        new_hp = max(0, hpmp.hp - damage)

        Game.Component.update(:hpmp, id, %{hpmp | hp: new_hp})

        percent = (new_hp / hpmp.max_hp * 100) |> floor()

        Game.Component.new(:sound, entity_id, %Sound{entity_id: id, sound_id: 349})
        IO.inspect(percent)
        IO.inspect(damage)
        Game.Component.new(:damage_entity, id, %DamageEntity{entity_id: id, percent: percent, amount: damage})

        if new_hp == 0 do
          killable = Game.Component.lookup(:killable, id)

          if killable == true do
            Game.World.delete_entity(id)
            Game.Component.HPMP.give_xp(entity_id, 1000)
          end
        end

      {_id, _} ->
        :noop
    end)
  end

  def calculate_swing_damage(entity_id, target_id) do
    min_base = 0
    max_base = 0

    base =
      cond do
        max_base - min_base > 0 -> :rand.uniform(max_base - min_base) + min_base
        max_base - min_base <= 0 -> 0
      end

    stat_might = 3
    stat_damage = 0

    mult_ingress = 1
    mult_rage = 1

    damage = (base / 2 * mult_ingress + stat_damage * 2.5 + stat_might / 8) * mult_rage

    target_ac = 100

    protection = 1 + target_ac / 100

    floor(protection * damage + 500)
  end
end
