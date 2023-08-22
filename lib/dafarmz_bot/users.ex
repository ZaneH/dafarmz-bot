defmodule DafarmzBot.Users do
  alias DafarmzBot.PlotItem
  alias DafarmzBot.{Repo, User, Farm, Plot}
  import Ecto.Query

  @sleep_cooldown_hours 1
  @daily_cooldown_days 1
  @refill_cooldown_minutes 30

  def setup_new_user(discord_id) do
    {:ok, user} =
      User.changeset(%User{}, %{discord_id: discord_id, money: 50000})
      |> Repo.insert()

    {:ok, farm} =
      Farm.changeset(%Farm{}, %{user_id: user.id})
      |> Repo.insert()

    {:ok, _} =
      Plot.changeset(%Plot{}, %{farm_id: farm.id})
      |> Repo.insert()

    {:ok, user}
  end

  def update_user(%User{} = user, changeset) do
    user
    |> User.changeset(changeset)
    |> Repo.update()
  end

  def deplete_energy(%User{} = user, amounts) do
    old_energies = user.energies
    new_energies = Map.merge(old_energies, amounts, fn _, old, new -> max(0, old - new) end)

    user
    |> User.changeset(%{energies: new_energies})
    |> Repo.update()
  end

  def add_harvest(%User{} = user, amounts) do
    total_yield =
      Enum.map(amounts, fn harvest_output ->
        case harvest_output do
          {_, :died} ->
            nil

          {%PlotItem{}, yield} ->
            yield

          {:error, _} ->
            nil

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Util.accumulate_maps()

    add_inventory(user, total_yield)
  end

  def add_inventory(%User{} = user, amounts) do
    old_inventory = user.inventory
    new_inventory = Map.merge(old_inventory, amounts, fn _, old, new -> old + new end)

    user
    |> User.changeset(%{inventory: new_inventory})
    |> Repo.update()
  end

  def deduct_inventory(%User{} = user, amounts) do
    old_inventory = user.inventory
    new_inventory = Map.merge(old_inventory, amounts, fn _, old, new -> old - new end)

    user
    |> User.changeset(%{inventory: new_inventory})
    |> Repo.update()
  end

  def get_by_discord_id(discord_id) when is_binary(discord_id) do
    query =
      from(u in User,
        where: u.discord_id == ^discord_id,
        select: u
      )

    case Repo.one(query) do
      nil ->
        nil

      user ->
        {:ok, user}
    end
  end

  def refill_energy(%User{} = user) do
    refill_cooldown = (user.cooldowns["refill"] || 0) |> Timex.from_unix()
    now = Timex.now()

    if Util.is_cooldown_ready?(refill_cooldown, @refill_cooldown_minutes, :minutes) do
      {:error,
       "You can use `daf refill` once every #{@refill_cooldown_minutes} minutes." <>
         "\nYou can use it again #{Util.format_cooldown_tag(refill_cooldown, @refill_cooldown_minutes, :minutes)}."}
    else
      max_water = Util.get_water_limit(user)
      max_energy = Util.get_energy_limit(user)

      new_energies =
        Map.put(user.energies, "water", max(max_water, user.energies["water"]))
        |> Map.put("energy", max(max_energy, user.energies["energy"]))

      {:ok, _} =
        user
        |> User.changeset(%{
          energies: new_energies,
          cooldowns: Map.put(user.cooldowns, "refill", now |> Timex.to_unix())
        })
        |> Repo.update()
    end
  end

  def sleep(%User{} = user) do
    sleep_cooldown = (user.cooldowns["sleep"] || 0) |> Timex.from_unix()
    now = Timex.now()

    if Util.has_item?(user, "bed") do
      if Util.is_cooldown_ready?(sleep_cooldown, @sleep_cooldown_hours, :hours) do
        {:error,
         "You can use `daf sleep` once an hour." <>
           "\nYou can use it again #{Util.format_cooldown_tag(sleep_cooldown, @sleep_cooldown_hours, :hours)}."}
      else
        rest_bonus = 100
        max_energy = Util.get_energy_limit(user) + rest_bonus

        new_energies =
          Map.put(user.energies, "energy", max(max_energy, user.energies["energy"] + rest_bonus))

        {:ok, _} =
          user
          |> User.changeset(%{
            energies: new_energies,
            cooldowns: Map.put(user.cooldowns, "sleep", now |> Timex.to_unix())
          })
          |> Repo.update()

        {:ok, "You slept for 8 hours and gained **#{rest_bonus}** energy!"}
      end
    else
      {:error, "You need a bed to sleep! You can buy one from the shop."}
    end
  end

  def claim_daily(%User{} = user) do
    daily_cooldown = (user.cooldowns["daily"] || 0) |> Timex.from_unix()
    now = Timex.now()

    if Util.is_cooldown_ready?(daily_cooldown, @daily_cooldown_days, :days) do
      {:error,
       "You can use `daf daily` once every 24 hours." <>
         "\nYou can use it again #{Util.format_cooldown_tag(daily_cooldown, @daily_cooldown_days, :days)}." <>
         "\n\nUse `daf help` to see what else you can do today."}
    else
      bonus_water = 200
      bonus_energy = 200

      new_energies =
        Map.put(user.energies, "water", max(bonus_energy, user.energies["water"] + bonus_water))
        |> Map.put("energy", max(bonus_energy, user.energies["energy"] + bonus_energy))

      {:ok, _} =
        user
        |> User.changeset(%{
          money: user.money + 100,
          energies: new_energies,
          cooldowns: Map.put(user.cooldowns, "daily", now |> Timex.to_unix())
        })
        |> Repo.update()

      {:ok,
       "You have claimed your daily bonus of **100** coins, " <>
         "**+#{bonus_energy}** energy, and **+#{bonus_water}** water!"}
    end
  end
end
