defmodule DafarmzBot.PlotItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plot_items" do
    field(:state, :string)
    field(:times_harvested, :integer, default: 0)

    belongs_to(:item, DafarmzBot.Item)
    belongs_to(:plot, DafarmzBot.Plot)

    timestamps()
  end

  def changeset(plot_item, attrs) do
    plot_item
    |> cast(attrs, [:item_id, :plot_id, :state])
    |> validate_required([:item_id, :state])
  end
end
