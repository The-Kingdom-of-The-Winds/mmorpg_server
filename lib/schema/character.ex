defmodule Schema.Character do
  import Ecto.Changeset
  use Ecto.Schema

  schema "characters" do
    field(:name, :string)
    field(:x, :integer)
    field(:y, :integer)
  end

  def changeset(character, attrs) do
    character
    |> cast(attrs, [:x, :y])
    |> validate_required([:name])
  end

  def get(id) do
    TkServer.Repo.get(Schema.Character, id)
  end

  def update(id, %{x: x, y: y}) do
    get(id)
    |> changeset(%{x: x, y: y})
    |> TkServer.Repo.update()
  end
end
