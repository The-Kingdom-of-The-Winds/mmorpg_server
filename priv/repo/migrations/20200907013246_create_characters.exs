defmodule TkServer.Repo.Migrations.CreateLogins do
  use Ecto.Migration

  def change do
    create table("characters") do
      add(:name, :string)
      add(:x, :integer)
      add(:y, :integer)

      timestamps()
    end
  end
end
