defmodule DafarmzBot.Controllers.PlotController do
  alias DafarmzBot.{Plots, Users, Shop}

  def setup(author_id, slash_command \\ true) do
    case Users.get_by_discord_id(to_string(author_id)) do
      {:ok, user} ->
        Responses.send_existing_user(user, slash_command)

      _ ->
        {:ok, user} = Users.setup_new_user(to_string(author_id))
        Responses.send_new_user(user, slash_command)
    end
  end

  def plant(author_id, item, spot, slash_command) do
    plant(author_id, "#{item} #{spot}", slash_command)
  end

  def plant(author_id, input, slash_command \\ false) do
    case ExRated.check_rate("plant-#{author_id}", 10_000, 4) do
      {:ok, _} ->
        matches = Regex.run(~r/(.+) ([A-fa-f]{1}[1-6]{1})/, input)
        destructure([_, item, spot], matches)

        if is_nil(item) or is_nil(spot) do
          Responses.send_error(
            "You need to specify an item and a spot to plant!\nExample: `daf plant strawberry A1`",
            slash_command
          )
        else
          case Users.get_by_discord_id(to_string(author_id)) do
            {:ok, user} ->
              case Shop.get_item_by_name(item) do
                nil ->
                  Responses.send_shop(user, slash_command)

                item ->
                  if user.inventory[item.name] == 0 do
                    Responses.send_error(
                      "You don't have any **#{item.name}** to plant!",
                      slash_command
                    )
                  else
                    plots = Plots.get_plot_by_user_id(user.id)

                    case Plots.plant_item(item.id, Enum.at(plots, 0).id, spot) do
                      {:ok, _} = _ ->
                        Users.deduct_inventory(user, %{
                          "#{item.name}" => 1
                        })

                        Users.deplete_energy(user, %{
                          "energy" => 15
                        })

                        Responses.send_planted(item, spot, slash_command)

                      {:error, error} ->
                        Responses.send_error(error, slash_command)
                    end
                  end
              end

            _ ->
              Responses.send_setup_message(slash_command)
          end
        end

      _ ->
        Responses.send_rate_limited(
          "Whoa there! You're doing that too fast. Try again in a few seconds.",
          slash_command
        )
    end
  end

  def harvest(author_id, slash_command \\ true) do
    case ExRated.check_rate("harvest-#{author_id}", 30_000, 1) do
      {:ok, _} ->
        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            plots = Plots.get_plot_by_user_id(user.id)

            if is_nil(plots) do
              Responses.send_setup_message(slash_command)
            else
              user_energy = user.energies["energy"]

              if user_energy < 5 do
                Responses.send_error(
                  "You don't have enough :zap: **energy** to harvest!",
                  slash_command
                )
              else
                harvest = Plots.harvest_plots(user, user_energy)
                Users.add_harvest(user, harvest)

                Responses.send_harvest(harvest, slash_command)
              end
            end

          _ ->
            Responses.send_setup_message(slash_command)
        end

      _ ->
        Responses.send_rate_limited(
          ":zzz: You're exhausted! Try again in 30 seconds.",
          slash_command
        )
    end
  end

  def plot(author_id, slash_command \\ true) do
    case ExRated.check_rate("plot-#{author_id}", 15_000, 3) do
      {:ok, _} ->
        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            case Plots.get_plot_by_user_id(user.id) do
              nil ->
                Responses.send_setup_message(slash_command)

              plot ->
                Responses.send_plot(
                  user,
                  Enum.at(plot, 0),
                  author_id,
                  slash_command
                )
            end

          _ ->
            Responses.send_setup_message(slash_command)
        end

      _ ->
        Responses.send_rate_limited(
          "Whoa there! You're doing that too fast. Try again in a few seconds.",
          slash_command
        )
    end
  end

  def remove(author_id, input, slash_command \\ true) do
    case ExRated.check_rate("remove-#{author_id}", 10_000, 4) do
      {:ok, _} ->
        matches = Regex.run(~r/([A-fa-f]{1}[1-6]{1})/, input)
        destructure([_, spot], matches)

        if is_nil(spot) do
          Responses.send_error(
            "You need to specify a spot!\nExample: `daf remove A1`",
            slash_command
          )
        else
          case Users.get_by_discord_id(to_string(author_id)) do
            {:ok, user} ->
              plots = Plots.get_plot_by_user_id(user.id)

              # TODO: deplete energy
              case Plots.remove_plant(Enum.at(plots, 0).id, spot) do
                {:ok, plot_item} ->
                  Responses.send_plant_removed(plot_item, spot, slash_command)

                {:error, error} ->
                  Responses.send_error(error, slash_command)
              end

            _ ->
              Responses.send_setup_message(slash_command)
          end
        end

      _ ->
        Responses.send_rate_limited(
          "Whoa there! You're doing that too fast. Try again in a few seconds.",
          slash_command
        )
    end
  end

  def info(author_id, input, slash_command \\ true) do
    matches = Regex.run(~r/([A-fa-f]{1}[1-6]{1})/, input)
    destructure([_, spot], matches)

    if is_nil(spot) do
      Responses.send_error("You need to specify a spot!\nExample: `daf info A1`", slash_command)
    else
      case Users.get_by_discord_id(to_string(author_id)) do
        {:ok, user} ->
          Responses.send_info(user, spot, slash_command)

        _ ->
          Responses.send_setup_message(slash_command)
      end
    end
  end

  def water(author_id, slash_command \\ false) do
    case ExRated.check_rate("water-#{author_id}", 5_000, 3) do
      {:ok, _} ->
        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            plots = Plots.get_plot_by_user_id(user.id)

            if is_nil(plots) do
              Responses.send_setup_message(slash_command)
            else
              user_water = user.energies["water"]
              user_energy = user.energies["energy"]

              if user_water < 5 or user_energy < 2 do
                message =
                  cond do
                    user_water < 5 ->
                      "You don't have enough :droplet: **water** for any plants!"

                    user_energy < 2 ->
                      "You don't have enough :zap: **energy** to water any plants!"
                  end

                Responses.send_error(
                  message,
                  slash_command
                )
              else
                watered = Plots.water_plots(plots, user_water, user_energy)

                num_watered = length(watered)

                Users.deplete_energy(user, %{
                  "water" => num_watered * 5,
                  "energy" => num_watered * 2
                })

                Responses.send_water_update(watered, slash_command)
              end
            end

          _ ->
            Responses.send_setup_message(slash_command)
        end

      _ ->
        Responses.send_rate_limited(
          ":zzz: You're too tired to water plants right now! Try again in a few seconds.",
          slash_command
        )
    end
  end
end
