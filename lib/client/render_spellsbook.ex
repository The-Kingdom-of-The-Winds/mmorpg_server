defmodule Client.RenderSpellbook do
  import TkServer.Commands, only: [add_spellbook_spell: 1, remove_spellbook_spell: 1]

  def render(nil, new), do: render_spells(new)

  def render(old, new) do
    derender = MapSet.difference(old, new) |> derender_spells()
    render = MapSet.difference(new, old) |> render_spells()

    [derender | render]
  end

  @doc """
    Generates the commands to render spells from the spellbook

  """
  def render_spells(spells), do: MapSet.to_list(spells) |> do_render_spells()

  defp do_render_spells([{position, spell} | rest]) do
    [
      add_spellbook_spell(
        position: position + 1,
        type: spell.type,
        name: spell.name,
        prompt: spell.prompt || nil
      )
      | do_render_spells(rest)
    ]
  end

  defp do_render_spells([]), do: []

  @doc """
    Generates the commands to derender spells from the inventory

    iex> derender_spells(MapSet.new(%{1 => [name: Test]}))
    [{:remove_spellbook_spell, 0}]
  """
  def derender_spells(spells), do: MapSet.to_list(spells) |> do_derender_spells()

  defp do_derender_spells([{position, _} | rest]) do
    [remove_spellbook_spell(position: position + 1) | do_derender_spells(rest)]
  end

  defp do_derender_spells([]), do: []
end
