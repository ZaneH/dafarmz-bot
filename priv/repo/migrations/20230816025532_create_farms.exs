defmodule DafarmzBot.Repo.Migrations.CreateFarms do
  use Ecto.Migration

  def change do
    create table(:farms) do
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
  end
end
