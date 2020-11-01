defmodule Game.Component.Position do
  defstruct [:instance_id, :x, :y, :direction]

  def adjacent(entity_id, :front) do
    %{x: x, y: y, direction: direction} = Game.Component.lookup(:position, entity_id)

    case direction do
      :north -> {x, y - 1}
      :east -> {x + 1, y}
      :west -> {x - 1, y}
      :south -> {x, y + 1}
    end
  end

  def adjacent(entity_id, :behind) do
    %{x: x, y: y, direction: direction} = Game.Component.lookup(:position, entity_id)

    case direction do
      :north -> {x, y + 1}
      :east -> {x - 1, y}
      :west -> {x + 1, y}
      :south -> {x, y - 1}
    end
  end

  def adjacent(entity_id, :left) do
    %{x: x, y: y, direction: direction} = Game.Component.lookup(:position, entity_id)

    case direction do
      :north -> {x - 1, y}
      :east -> {x, y - 1}
      :west -> {x, y + 1}
      :south -> {x + 1, y}
    end
  end

  def adjacent(entity_id, :right) do
    %{x: x, y: y, direction: direction} = Game.Component.lookup(:position, entity_id)

    case direction do
      :north -> {x + 1, y}
      :east -> {x, y + 1}
      :west -> {x, y - 1}
      :south -> {x - 1, y}
    end
  end
end
