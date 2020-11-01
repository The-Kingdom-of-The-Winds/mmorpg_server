defmodule Scripts.DropMoney do
  alias Game.Component
  alias Game.Component.{Broadcast, Gold, Position, ItemLook, Name, Wallet, Pickupable}

  def on_drop_money(entity_id, input_amount) do
    %{balance: current_balance} = Component.lookup(:wallet, entity_id)

    # If we try to drop more than we have, drop our entire wallet balance
    amount = min(current_balance, input_amount)
    do_drop_money(entity_id, amount)
  end

  defp do_drop_money(_entity_id, 0), do: :noop

  defp do_drop_money(entity_id, amount) do
    %{balance: current_balance} = Component.lookup(:wallet, entity_id)
    Component.update(:wallet, entity_id, %Wallet{balance: current_balance - amount})

    Broadcast.add_status(entity_id, "You dropped #{amount} coins")

    player_pos = Component.lookup(:position, entity_id)

    id = :rand.uniform(9_999_999)
    Game.World.add_entity(id, :item)
    Component.new(:look, id, %ItemLook{icon_id: get_money_icon(amount), color_id: 0})
    Component.new(:name, id, %Name{name: get_money_name(amount)})
    Component.new(:gold, id, %Gold{amount: amount})

    Component.new(:position, id, %Position{
      instance_id: player_pos.instance_id,
      x: player_pos.x,
      y: player_pos.y
    })

    Component.new(:pickupable, id, %Pickupable{})
  end

  def get_money_name(amount) do
    case amount do
      _ when amount == 1 -> "Penny"
      _ when amount >= 1 and amount <= 99 -> "Penny roll (#{amount})"
      _ when amount >= 100 and amount <= 999 -> "Silver coins roll (#{amount})"
      _ -> "Gold Nugget (#{amount})"
    end
  end

  def get_money_icon(amount) do
    case amount do
      _ when amount == 1 -> 49174
      _ when amount >= 1 and amount <= 99 -> 49225
      _ when amount >= 100 and amount <= 999 -> 49224
      _ -> 49223
    end
  end
end
