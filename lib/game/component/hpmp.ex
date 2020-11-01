defmodule Game.Component.HPMP do
  defstruct [:level, :total_xp, :hp, :mp, :max_hp, :max_mp]

  def give_xp(entity_id, amount) do
    stats = Game.Component.lookup(:hpmp, entity_id)
    Game.Component.update(:hpmp, entity_id, %{total_xp: stats.total_xp + amount})
    Game.Component.Broadcast.add_status(entity_id, "#{amount} experience!")
    stats = Game.Component.lookup(:hpmp, entity_id)

    check_level(entity_id, stats)
  end

  def check_level(entity_id, %{total_xp: total_xp, level: level}) do
    level_breakpoints = [0, 2000, 4000, 5000, 6000, 11000, 14000]

    new_level = Enum.reduce_while(level_breakpoints, 0, fn tnl, acc ->
      if total_xp >= tnl, do: {:cont, acc + 1}, else: {:halt, acc}
    end)

    if new_level != level do
      Game.Component.Broadcast.add_status(entity_id, "A rush of insight fills you!")
      Game.Component.update(:hpmp, entity_id, %{level: new_level})
      Game.Component.new(:sound, entity_id, %Game.Component.Sound{entity_id: entity_id, sound_id: 123})
      Game.Component.new(:animation, entity_id, %Game.Component.Animation{entity_id: entity_id, animation_id: 2})
    end
  end
end
