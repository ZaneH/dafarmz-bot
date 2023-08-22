defmodule DafarmzBot.Item do
  use Ecto.Schema

  schema "items" do
    field(:name, :string)
    field(:cost, :integer)
    field(:removal_requirements, :map)
    field(:lifecycle_images, {:array, :string})
    field(:growth_odds, :float)
    field(:yield, :map)
    field(:max_harvests, :integer)
    field(:item_type, :string, default: "plant")
    field(:description, :string)
    field(:chance_items, :map, default: %{})

    has_many(:plot_items, DafarmzBot.PlotItem)

    timestamps()
  end
end
