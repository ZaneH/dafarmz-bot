defmodule DafarmzBot.Repo.Migrations.CreatePlotItems do
  use Ecto.Migration

  def change do
    create table(:plot_items) do
      add :plot_id, references(:plots)
      add :item_id, references(:items)
      add :state, :string

      timestamps()
    end
  end
end
