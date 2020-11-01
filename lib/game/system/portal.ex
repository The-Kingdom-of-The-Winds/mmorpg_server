defmodule Game.System.Portal do
  def tick(_) do
    position = :ets.tab2list(:position)

    Enum.map(position, fn {id, position} ->
      case Game.Component.lookup(:tile_warp, {position.instance_id, position.x, position.y}) do
        %Game.Component.TileWarp{instance_id: i, x: x, y: y} ->
          Game.Component.update(:camera, id, %{
            instance_id: i,
            x0: x - 8,
            y0: y - 8,
            x1: x + 8,
            y1: y + 8
          })

          Game.Component.update(:position, id, %{instance_id: i, x: x, y: y})

        _ ->
          nil
      end
    end)
  end
end
