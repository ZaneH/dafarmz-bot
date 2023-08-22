defmodule DafarmzBot.Plots do
  alias DafarmzBot.{Plot, Farms, PlotItem, Repo, Users, Shop}
  import Ecto.Query

  def get_plot_by_user_id(user_id) do
    farm = Farms.get_farm_by_user_id(user_id)

    Repo.all(
      from(p in Plot,
        where: p.farm_id == ^farm.id,
        select: p,
        # TODO: Change this for multiple plots
        limit: 1
      )
    )
  end

  def get_plot_by_id(plot_id) do
    Repo.get_by(Plot, id: plot_id)
  end

  def get_plot_items_from_layout(plot_layout) do
    plot_item_ids =
      plot_layout
      |> Map.values()

    plot_items =
      Repo.all(
        from(pi in PlotItem,
          where: pi.id in ^plot_item_ids and pi.state != "dead" and pi.state != "removed",
          select: pi
        )
      )
      |> Repo.preload(:item)

    # check if plot_items is empty, return empty map
    if Enum.empty?(plot_items) do
      %{}
    else
      Enum.map(plot_layout, fn {spot, plot_item_id} ->
        %{"#{spot}" => Enum.find(plot_items, fn pi -> pi.id == plot_item_id end)}
      end)
      |> Enum.reduce(&Map.merge/2)
    end
  end

  def get_plot_item_by_id(plot_item_id) do
    Repo.get_by(PlotItem, id: plot_item_id)
    |> Repo.preload(:item)
  end

  def get_active_plot_items_by_plot_id(plot_id) do
    Repo.all(
      from(pi in PlotItem,
        where: pi.plot_id == ^plot_id and pi.state != "dead" and pi.state != "removed",
        select: pi
      )
    )
    |> Repo.preload(:item)
  end

  def update_plot(%Plot{} = plot, attrs) do
    plot
    |> Plot.changeset(attrs)
    |> Repo.update()
  end

  def update_plot_item(%PlotItem{} = plot_item, attrs) do
    plot_item
    |> PlotItem.changeset(attrs)
    |> Repo.update()
  end

  def try_to_grow_plot_item(%PlotItem{} = plot_item) do
    lifecycle_max = length(plot_item.item.lifecycle_images)
    growth_odds = plot_item.item.growth_odds
    random = :rand.uniform()

    success = random <= growth_odds

    case plot_item.state do
      "removed" ->
        nil

      state ->
        case String.split(state, ":") do
          ["growing", stage] ->
            stage_int = String.to_integer(stage)

            if stage_int < lifecycle_max - 1 do
              new_stage = stage_int + 1

              if success do
                update_plot_item(plot_item, %{state: "growing:#{new_stage}"})
              else
                :no_growth
              end
            else
              nil
            end

          _ ->
            IO.puts(
              "[INFO] Unknown plot item state: #{plot_item.state} for advancement. Skipping."
            )

            nil
        end
    end
  end

  def increment_times_harvested(plot_item_ids) do
    Repo.update_all(
      from(pi in PlotItem,
        where: pi.id in ^plot_item_ids,
        update: [inc: [times_harvested: 1]]
      ),
      []
    )
  end

  def kill_plot_items(plots, plot_items) do
    plot_item_ids = Enum.map(plot_items, fn pi -> pi.id end)

    Repo.update_all(
      from(pi in PlotItem,
        where: pi.id in ^plot_item_ids,
        update: [set: [state: "dead"]]
      ),
      []
    )

    # update layout for plots removing dead items
    Enum.each(plots, fn plot ->
      plot_layout = plot.layout

      plot_layout =
        Map.reject(plot_layout, fn {_, plot_item_id} ->
          plot_item_id in plot_item_ids
        end)

      update_plot(plot, %{layout: plot_layout})
    end)

    Enum.map(plot_items, fn pi ->
      {pi, :died}
    end)
  end

  def harvest_plots(user, energy_limit) do
    plots = get_plot_by_user_id(user.id)

    plot_items =
      Enum.flat_map(plots, fn plot ->
        get_active_plot_items_by_plot_id(plot.id)
      end)

    results =
      for i <-
            0..Enum.min([
              length(plot_items),
              trunc(energy_limit / 5)
            ]) do
        plot_item = Enum.at(plot_items, i)

        if not is_nil(plot_item) do
          harvest_plot_item(plot_item)
        end
      end

    plot_item_ids =
      Enum.map(results, fn result ->
        case result do
          {%PlotItem{} = p, _} -> p.id
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    reached_max_harvest_items =
      Enum.map(results, fn result ->
        case result do
          {%PlotItem{} = p, _yield} ->
            if p.item.max_harvests <= p.times_harvested + 1 do
              p
            else
              nil
            end

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    increment_times_harvested(plot_item_ids)
    dead_items = kill_plot_items(plots, reached_max_harvest_items)
    results = results ++ dead_items

    total_energy_spent =
      Enum.reduce(results, 0, fn result, acc ->
        case result do
          {:error, _} ->
            acc

          nil ->
            acc

          _ ->
            acc + 5
        end
      end)

    Users.deplete_energy(user, %{
      "energy" => total_energy_spent
    })

    results |> Enum.reject(&is_nil/1)
  end

  def harvest_plot_item(%PlotItem{} = plot_item) do
    lifecycle_max = length(plot_item.item.lifecycle_images) - 1

    if plot_item.state == "growing:#{lifecycle_max}" do
      case plot_item.state do
        state ->
          case String.split(state, ":") do
            ["growing", _] ->
              new_stage = 1
              {:ok, updated} = update_plot_item(plot_item, %{state: "growing:#{new_stage}"})

              chance_items = Util.get_random_from_chance_items(plot_item.item.chance_items)
              {updated, Map.merge(plot_item.item.yield, chance_items)}

            _ ->
              {:error, "This plot item cannot be harvested."}
          end
      end
    else
      {:error, "This plot item is not ready to be harvested."}
    end
  end

  def plant_item(item_id, plot_id, spot) do
    plot = get_plot_by_id(plot_id)
    item = Shop.get_item_by_id(item_id)
    spot = String.downcase(spot)

    if plot.layout |> Map.has_key?(spot) do
      {:error, "There's already something planted at **#{spot}**..."}
    else
      if is_nil(item.lifecycle_images) do
        {:error, "This item cannot be planted."}
      else
        {:ok, plot_item} =
          %PlotItem{}
          |> PlotItem.changeset(%{plot_id: plot.id, item_id: item.id, state: "growing:0"})
          |> Repo.insert()

        update_plot(plot, %{layout: Map.put(plot.layout, spot, plot_item.id)})
      end
    end
  end

  def remove_plant(plot_id, spot) do
    plot = get_plot_by_id(plot_id)
    spot = String.downcase(spot)
    plot_item_id = Map.get(plot.layout, spot)

    if not is_nil(plot_item_id) do
      plot_item = get_plot_item_by_id(plot_item_id)
      update_plot_item(plot_item, %{state: "removed"})
      update_plot(plot, %{layout: Map.delete(plot.layout, spot)})
      {:ok, plot_item}
    else
      {:error, "There's nothing at **#{spot}**..."}
    end
  end

  def water_plots(plots, water_limit, energy_limit) do
    # attempt to grow plant with water
    plot_items =
      Enum.flat_map(plots, fn plot ->
        get_active_plot_items_by_plot_id(plot.id)
      end)

    results =
      for i <-
            0..Enum.min([
              length(plot_items),
              trunc(water_limit / 5),
              trunc(energy_limit / 2)
            ]) do
        plot_item = Enum.at(plot_items, i)

        if not is_nil(plot_item) do
          try_to_grow_plot_item(plot_item)
        end
      end

    # update last_watered_at
    plot_ids =
      Enum.uniq(
        for result <- results do
          case result do
            {:ok, plot_item} ->
              plot_item.plot_id

            _ ->
              nil
          end
        end
      )

    Enum.map(plot_ids, fn plot_id ->
      if not is_nil(plot_id) do
        plot = get_plot_by_id(plot_id)
        update_plot(plot, %{last_watered_at: DateTime.utc_now()})
      end
    end)

    results |> Enum.reject(&is_nil/1)
  end
end
