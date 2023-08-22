defmodule DafarmzBot.Farm do
  use Ecto.Schema
  import Ecto.Changeset

  schema "farms" do
    belongs_to(:user, DafarmzBot.User)

    timestamps()
  end

  def changeset(farm, params \\ %{}) do
    farm
    |> cast(params, [:user_id])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
  end
end
