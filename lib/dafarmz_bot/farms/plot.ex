defmodule DafarmzBot.Plot do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plots" do
    field(:layout, :map, default: %{})
    field(:last_watered_at, :utc_datetime)

    belongs_to(:farm, DafarmzBot.Farm, foreign_key: :farm_id)

    timestamps()
  end

  def changeset(plot, params \\ %{}) do
    plot
    |> cast(params, [:layout, :farm_id, :last_watered_at])
    |> foreign_key_constraint(:farm_id)
  end
end
