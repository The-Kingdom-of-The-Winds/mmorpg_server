defmodule Game.System.TransformPosition do
  def tick(_tick) do
    transforms = :ets.tab2list(:transform_position)

    Enum.map(transforms, fn {id, %{direction: direction, x: x, y: y}} ->
      Game.Component.update(:position, id, %{direction: direction, x: x, y: y})
    end)

    :ets.delete_all_objects(:transform_position)
  end
end
