defmodule DafarmzBot.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:discord_id, :string)
    field(:money, :integer, default: 0)
    field(:energies, :map, default: %{"energy" => 50, "water" => 100})
    field(:inventory, :map, default: %{"strawberry" => 0, "apple" => 0})
    field(:cooldowns, :map, default: %{})

    has_one(:farm, DafarmzBot.Farm)

    timestamps()
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:discord_id, :money, :energies, :inventory, :cooldowns])
    |> validate_required([:discord_id])
    |> unique_constraint(:farm_id)
  end
end
