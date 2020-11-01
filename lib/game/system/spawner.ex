alias Game.Component

defmodule Game.System.Spawner do
  def tick(_) do
    spawners = :ets.tab2list(:spawner)

    Enum.map(spawners, fn {id, %{mob_limit: ml} = spawner} ->
      case Game.Component.lookup(:spawned, id) do
        amt when not is_list(amt) or length(amt) <= ml ->
          IO.inspect("SPAWNING")
          template = Game.Component.lookup(:mob_template, spawner[:mob_template])
          bounding_box = Game.Component.lookup(:bounding_box, id)

          x = :rand.uniform(bounding_box[:x1] - bounding_box[:x0]) + bounding_box[:x0]
          y = :rand.uniform(bounding_box[:y1] - bounding_box[:y0]) + bounding_box[:y0]

          e_id = :rand.uniform(400_000_000)

          direction =
            case :rand.uniform(4) do
              1 -> :north
              2 -> :west
              3 -> :east
              4 -> :south
            end

          Component.new(:hpmp, e_id, template.hpmp)
          Component.new(:position, e_id, %Game.Component.Position{instance_id: 0, x: x, y: y, direction: direction})
          Component.new(:look, e_id, template.look)
          Component.new(:killable, e_id, true)
          Component.new(:spawned, id, e_id)

        _ ->
          :noop
      end
    end)

    # Component.new(:mob_template, 554, %{hpmp: %HPMP{max_hp: 10, hp: 10}, look: %MobLook{graphic_id: 25, color_id: 9}})

    # Component.new(:bounding_box, 555, %{room_id: 0, x0: 180, y0: 100, x1: 200, y1: 120})
    # Component.new(:spawner, 555, %{mob_template: 554})
  end
end
