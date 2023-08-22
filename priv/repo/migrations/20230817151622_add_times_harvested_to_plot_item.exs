defmodule DafarmzBot.Repo.Migrations.AddTimesHarvestedToPlotItem do
  use Ecto.Migration

  def change do
    alter table(:plot_items) do
      add :times_harvested, :integer, default: 0
    end
  end
end
