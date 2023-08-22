defmodule DafarmzBot.Repo.Migrations.CreatePlots do
  use Ecto.Migration

  def change do
    create table(:plots) do
      add :farm_id, references(:farms, on_delete: :delete_all)
      add :layout, :map
      add :last_watered_at, :utc_datetime

      timestamps()
    end
  end
end
