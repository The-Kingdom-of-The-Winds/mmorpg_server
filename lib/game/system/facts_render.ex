defmodule Game.System.SidebarRender do
  def tick() do
    cameras = :ets.tab2list(:camera)

    Enum.map(cameras, fn {id, %{client_id: client_id}} ->
      hpmp = Game.Component.lookup(:hpmp, id)
      wallet = Game.Component.lookup(:wallet, id)
      inventory = Game.Component.lookup(:inventory, id)

      broadcasts = Game.Component.lookup(:broadcast, id)
      Client.render(%{stats: hpmp, coins: wallet, xp: %{amount: hpmp.total_xp, percent: 65}}, :stats, client_id)

      spellbook = %{
        0 => %{type: :prompt, name: "Gateway", prompt: "What Gate?"},
        1 => %{type: :target, name: "Restore", prompt: nil},
        2 => %{type: :self, name: "Whirlwind", prompt: nil},
        3 => %{type: :target, name: "Heal", prompt: nil},
        4 => %{type: :target, name: "Sanctuary", prompt: nil},
        5 => %{type: :target, name: "Harden Body", prompt: nil}
      }

      Client.render(MapSet.new(spellbook), :spellbook, client_id)

      inventory_state =
        Enum.map(inventory.items, fn {position, item_id} ->
          %{name: name} = Game.Component.lookup(:name, item_id)
          %{icon_id: icon_id, color_id: color_id} = Game.Component.lookup(:look, item_id)
          {position, %{:name => name, icon_id: icon_id, color_id: color_id}}
        end)

      Client.render(MapSet.new(inventory_state), :inventory, client_id)

      case broadcasts do
        [] ->
          nil

        broadcasts ->
          Client.render([broadcasts], :broadcasts, client_id)
      end
    end)
  end
end
