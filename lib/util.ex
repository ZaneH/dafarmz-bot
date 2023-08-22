defmodule Util do
  def accumulate_maps(maps) when is_list(maps) do
    Enum.reduce(maps, %{}, fn map, acc ->
      Map.merge(map, acc, fn _, val1, val2 -> val1 + val2 end)
    end)
  end

  def is_cooldown_ready?(last_timestamp, cooldown, unit \\ :hours) do
    now = Timex.now()
    time_difference = Timex.diff(now, last_timestamp, unit)

    time_difference < cooldown
  end

  def format_cooldown_tag(last_ts, cooldown, unit \\ :hours) do
    duration =
      case unit do
        :seconds -> Timex.Duration.from_seconds(cooldown)
        :minutes -> Timex.Duration.from_minutes(cooldown)
        :hours -> Timex.Duration.from_hours(cooldown)
        :days -> Timex.Duration.from_days(cooldown)
      end

    able_ts = Timex.add(last_ts, duration) |> Timex.to_unix()

    "<t:#{able_ts}:R>"
  end

  def get_water_limit(user) do
    cond do
      has_item?(user, "water_bag") -> 300
      true -> 100
    end
  end

  def get_energy_limit(user) do
    cond do
      has_item?(user, "caffeine") -> 200
      true -> 100
    end
  end

  def has_item?(user, item_name) do
    Map.get(user.inventory, item_name, 0) > 0
  end

  def get_random_from_chance_items(chance_items) do
    for {item, [chance, amount]} <- chance_items do
      if :rand.uniform() < chance do
        {item, amount}
      end
    end
    |> Enum.reject(&is_nil/1)
    |> Enum.into(%{})
  end

  def emoji_for_energy("water"), do: ":droplet:"
  def emoji_for_energy("energy"), do: ":zap:"

  def emoji_for_item(item_name) do
    cond do
      item_name =~ "scrap" -> ":fallen_leaf:"
      item_name =~ "tree" -> ":deciduous_tree:"
      item_name =~ "apple" -> ":apple:"
      item_name =~ "strawberry" -> ":strawberry:"
      item_name =~ "blueberry" -> ":blueberries:"
      item_name =~ "water" -> ":droplet:"
      item_name =~ "bed" -> ":bed:"
      item_name =~ "orange" -> ":tangerine:"
      item_name =~ "peach" -> ":peach:"
      item_name =~ "pear" -> ":pear:"
      item_name =~ "carrot" -> ":carrot:"
      item_name =~ "grape" -> ":grapes:"
      item_name =~ "potato" -> ":potato:"
      item_name =~ "corn" -> ":corn:"
      item_name =~ "tomato" -> ":tomato:"
      item_name =~ "eggplant" -> ":eggplant:"
      item_name =~ "pumpkin" -> ":jack_o_lantern:"
      item_name =~ "pickle" -> ":cucumber:"
      item_name =~ "caffeine" -> ":coffee:"
      true -> ":seedling:"
    end
  end

  def format_currency(amount) do
    (amount / 100)
    |> Number.Currency.number_to_currency(precision: 2, unit: "")
    |> String.replace(".00", "")
  end

  def format_yields(yield) do
    Enum.map(yield, fn {item_name, amount} ->
      "#{emoji_for_item(item_name)} #{amount} #{item_name}"
    end)
    |> Enum.join("\n")
  end

  def format_energies(energies, inline \\ false) do
    Enum.map(energies, fn {energy, amount} ->
      "> #{emoji_for_energy(energy)} | #{amount} #{energy}"
    end)
    |> Enum.join(if inline, do: "\t", else: "\n")
  end
end
