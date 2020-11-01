defmodule Client.RenderStats do
  import TkServer.Commands, only: [set_player_stats: 1]

  def render(old, new) when old == new, do: []

  def render(_old, %{stats: stats, coins: coins, xp: xp}) do
    set_player_stats(
      level: stats.level,
      hp: stats.hp,
      max_hp: stats.max_hp,
      mp: stats.mp,
      max_mp: stats.max_mp,
      coins: coins.balance,
      xp: xp.amount,
      xp_percent: xp.percent
    )
  end
end
