defmodule DafarmzBot.Farms do
  alias DafarmzBot.{Repo, Farm}
  import Ecto.Query

  def create_farm(user_id) do
    Farm.changeset(%Farm{}, %{user_id: user_id})
    |> Repo.insert()
  end

  def get_farm_by_user_id(user_id) do
    query =
      from(f in Farm,
        where: f.user_id == ^user_id,
        select: f
      )

    Repo.one(query)
  end
end
