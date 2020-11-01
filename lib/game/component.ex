defmodule Game.Component do
  def init(name) do
    :ets.new(name, [:named_table, :public])
  end

  def init(name, :bag) do
    :ets.new(name, [:named_table, :bag, :public])
  end

  def new(type, entity_id, state) do
    :ets.insert(type, {entity_id, state})
  end

  def update(type, entity_id, changeset) do
    val = lookup(type, entity_id)
    new = Map.merge(val, changeset)

    :ets.insert(type, {entity_id, new})
  end

  def lookup(type, id) do
    case :ets.lookup(type, id) do
      [] -> []
      [{_, v}] -> v
      all -> all
    end
  end
end
