defmodule DafarmzBot.Repo.Migrations.AddChanceItemsToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :chance_items, :map, default: %{}
    end
  end
end
