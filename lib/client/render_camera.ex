defmodule Client.RenderCamera do
  import TkServer.Commands, only: [remove_entity: 1]
  require Logger

  # def render(old, new) do
  # end

  def derender_entities(old, new, player_id) do
    derender = MapSet.difference(old, new)

    if MapSet.member?(derender, player_id) do
      Logger.warn("BUG- Attempting to derender the player, this will crash the client")
    end

    MapSet.to_list(derender) |> derender_entities()
  end

  def derender_entities([entity_id | rest]) do
    [remove_entity(entity_id: entity_id) | derender_entities(rest)]
  end

  def derender_entities([]), do: []
end
