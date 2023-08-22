defmodule DafarmzBot.Repo.Migrations.AddItemTypeToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :item_type, :string, default: "plant"
      add :description, :text
    end
  end
end
