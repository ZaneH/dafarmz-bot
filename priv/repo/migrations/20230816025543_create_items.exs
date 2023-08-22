defmodule DafarmzBot.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :name, :string
      add :cost, :integer
      add :removal_requirements, :map
      add :lifecycle_images, {:array, :string}
      add :growth_odds, :float
      add :yield, :map
      add :max_harvests, :integer

      timestamps()
    end
  end
end
