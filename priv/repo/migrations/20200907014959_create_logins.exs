defmodule TkServer.Repo.Migrations.CreateLogins do
  use Ecto.Migration

  def change do
    create table("logins") do
      add(:name, :string)
      add(:password, :string)
      add(:character_id, references(:characters))

      timestamps()
    end
  end
end
