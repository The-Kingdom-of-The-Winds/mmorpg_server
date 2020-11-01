defmodule Scripts.Talking do
  def on_talk(entity_id, <<"/look armor ", armor_id::bitstring>>, _type) do
    Game.Component.update(:look, entity_id, %{armor_id: String.to_integer(armor_id)})
  end

  def on_talk(entity_id, <<"/look armor_color ", armor_color_id::bitstring>>, _type) do
    Game.Component.update(:look, entity_id, %{armor_color_id: String.to_integer(armor_color_id)})
  end

  def on_talk(entity_id, <<"/look weapon ", weapon_id::bitstring>>, _type) do
    Game.Component.update(:look, entity_id, %{weapon_id: String.to_integer(weapon_id)})
  end

  def on_talk(entity_id, <<"/warp ", instance_id::bitstring>>, _type) do
    Game.Component.update(:camera, entity_id, %{
      instance_id: String.to_integer(instance_id),
      x0: 0,
      y0: 0,
      x1: 15,
      y1: 17
    })

    Game.Component.update(:position, entity_id, %{instance_id: String.to_integer(instance_id), x: 8, y: 8})
  end

  def on_talk(entity_id, message, type) do
    %{name: name} = Game.Component.lookup(:name, entity_id)
    Game.Component.new(:talking, entity_id, %Game.Component.Talking{type: type, message: "#{name}: #{message}"})
  end
end
