defmodule Client.RenderInventory do
  import TkServer.Commands, only: [add_inventory_item: 1, remove_inventory_item: 1]

  def render(nil, new) do
    render_items(new)
  end

  def render(old, new) do
    derender = MapSet.difference(old, new) |> derender_items()
    render = MapSet.difference(new, old) |> render_items()

    [derender | render]
  end

  @doc """
    Generates the commands to render items from the inventory

  """
  def render_items(items), do: MapSet.to_list(items) |> do_render_items()

  defp do_render_items([{position, item} | rest]) do
    [
      add_inventory_item(
        position: position + 1,
        icon_id: item.icon_id,
        icon_color_id: item.color_id,
        name: item.name,
        description: item.name
      )
      | do_render_items(rest)
    ]
  end

  defp do_render_items([]), do: []

  @doc """
    Generates the commands to derender items from the inventory

    iex> derender_items(MapSet.new(%{1 => [name: Test]}))
    [{:remove_inventory_item, 0, true}]
  """
  def derender_items(items), do: MapSet.to_list(items) |> do_derender_items()

  defp do_derender_items([{position, _} | rest]) do
    [remove_inventory_item(position: position + 1, remove_item_type: :none) | do_derender_items(rest)]
  end

  defp do_derender_items([]), do: []
end
