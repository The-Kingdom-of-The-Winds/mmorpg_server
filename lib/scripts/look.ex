defmodule Scripts.Look do
  alias Game.Component.{Broadcast}

  def on_look({entity_id}) do
    # Entity.get(:position, entity_id)

    # {i, x, y} = Entity.get_facing(entity_id)

    # Position.at({i, x, y}, :name)

    entity_pos = Game.Component.lookup(:position, entity_id)
    target_i = entity_pos.instance_id

    {target_x, target_y} =
      case entity_pos.direction do
        :north -> {entity_pos.x, entity_pos.y - 1}
        :east -> {entity_pos.x + 1, entity_pos.y}
        :west -> {entity_pos.x - 1, entity_pos.y}
        :south -> {entity_pos.x, entity_pos.y + 1}
      end

    position = :ets.tab2list(:position)

    Enum.map(position, fn
      {id, %{instance_id: ^target_i, x: ^target_x, y: ^target_y}} ->
        case Game.Component.lookup(:name, id) do
          %{name: name} -> Broadcast.add_status(entity_id, name)
          _ -> :noop
        end

      {_id, _} ->
        :noop
    end)
  end
end
