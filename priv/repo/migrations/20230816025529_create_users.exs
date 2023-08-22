defmodule DafarmzBot.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :discord_id, :string
      add :money, :integer, default: 0
      add :energies, :map, default: %{"energy" => 50, "water" => 100}
      add :inventory, :map, default: %{"strawberry" => 0, "apple" => 0}

      timestamps()
    end
  end
end
