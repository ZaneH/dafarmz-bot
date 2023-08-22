defmodule Responses do
  alias DafarmzBot.{Plots, Shop}
  alias Nostrum.Struct.Embed

  def send_user(user, slash_command \\ false) do
    data = %{
      content:
        "> :coin: | #{Util.format_currency(user.money)} coins" <>
          "\n#{Util.format_energies(user.energies)}" <>
          "\n\n*use `daf plot` to see your farm*"
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_setup_message(slash_command \\ false) do
    data = %{
      content: "Use `daf setup` to get started!"
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_new_user(user, slash_command \\ false) do
    data = %{
      content:
        "Welcome! You have been given :coin: **#{Util.format_currency(user.money)}** coins to start with." <>
          "\n\n*use `daf plot` to see your farm*"
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_existing_user(user, slash_command \\ false) do
    data = %{
      content:
        "Welcome back! You have :coin: **#{Util.format_currency(user.money)}** coins." <>
          "\n\n*use `daf plot` to see your farm*"
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_plot(user, plot, discord_user_id, slash_command \\ false) do
    layout = plot.layout
    plot_items = Plots.get_plot_items_from_layout(layout)

    js_input =
      for {spot, _} <- layout do
        {grid_x, _} = :binary.match("abcdef", String.at(spot, 0) |> String.downcase())
        grid_y = String.at(spot, 1) |> String.to_integer()

        plot_item = Map.get(plot_items, spot)

        if not is_nil(plot_item) do
          stage =
            case plot_item.state do
              "growing:" <> stage ->
                stage |> String.to_integer()

              _ ->
                0
            end

          %{
            x: grid_x + 1,
            y: grid_y,
            image: Enum.at(plot_item.item.lifecycle_images, stage)
          }
        end
      end

    {:ok, path} =
      NodeJS.call("app", [
        Jason.encode!(%{"discord_user_id" => user.discord_id, "state" => js_input})
      ])

    data = %{
      content:
        "> <@#{discord_user_id}>\n> :coin: | #{Util.format_currency(user.money)}\n#{Util.format_energies(user.energies)}",
      file: %{
        name: "plot.png",
        body: File.read!("#{path}")
      }
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_info(user, spot, true = _slash_command) do
    spot = String.downcase(spot)
    plot = Plots.get_plot_by_user_id(user.id) |> Enum.at(0)
    plot_item_id = plot.layout[spot]

    embed =
      %Nostrum.Struct.Embed{}
      |> Embed.put_title("Info")
      |> Embed.put_color(12_637_296)
      |> Embed.put_description("Here's all the info we could find on this spot:")
      |> Embed.put_field("Spot", spot |> String.upcase())

    embed =
      if not is_nil(plot_item_id) do
        plot_item = Plots.get_plot_item_by_id(plot_item_id)

        embed
        |> Embed.put_field("Plant", plot_item.item.name)
        |> Embed.put_field(
          "Stage",
          "#{plot_item.state |> String.replace(":", ": ")}/#{length(plot_item.item.lifecycle_images) - 1}"
        )
        |> Embed.put_field("Yield", plot_item.item.yield |> Util.format_yields())
      else
        embed
      end

    %{
      type: 4,
      data: %{
        embeds: [embed]
      }
    }
  end

  def send_info(user, spot, false = _slash_command) do
    spot = String.downcase(spot)
    plot = Plots.get_plot_by_user_id(user.id) |> Enum.at(0)
    plot_item_id = plot.layout[spot]

    fields = [
      %{
        name: "Spot",
        value: spot |> String.upcase()
      }
    ]

    fields =
      if not is_nil(plot_item_id) do
        plot_item = Plots.get_plot_item_by_id(plot_item_id)

        fields ++
          [
            %{
              name: "Plant",
              value: plot_item.item.name
            },
            %{
              name: "Stage",
              value:
                "#{plot_item.state |> String.replace(":", ": ")}/#{length(plot_item.item.lifecycle_images) - 1}"
            },
            %{
              name: "Yield",
              value: plot_item.item.yield |> Util.format_yields()
            }
          ]
      else
        fields
      end

    %{
      embed: %{
        title: "Info",
        description: "Here's all the info we could find on this spot:",
        fields: fields
      }
    }
  end

  def send_inventory(user, true = _slash_command) do
    inventory = user.inventory |> Enum.filter(fn {_, amount} -> amount > 0 end)

    embed =
      %Nostrum.Struct.Embed{}
      |> Embed.put_title("Inventory")
      |> Embed.put_color(12_884_588)

    embed =
      if Enum.empty?(inventory) do
        embed
        |> Embed.put_description("You have no items in your inventory.")
      else
        embed
        |> Embed.put_description(
          inventory
          |> Enum.map(fn {item, amount} ->
            shop_item = Shop.get_item_by_name(item)

            "#{Util.emoji_for_item(item)} **#{item}** (#{amount})\n" <>
              "#{shop_item.description}"
          end)
          |> Enum.join("\n\n")
        )
      end

    %{
      type: 4,
      data: %{
        embeds: [embed]
      }
    }
  end

  def send_inventory(user) do
    inventory =
      user.inventory
      |> Enum.filter(fn {_, amount} -> amount > 0 end)

    fields =
      Enum.map(inventory, fn {item, amount} ->
        shop_item = Shop.get_item_by_name(item)

        %{
          name: item,
          value: "#{Util.emoji_for_item(item)} #{amount}\n#{shop_item.description}"
        }
      end)

    fields =
      if Enum.empty?(fields) do
        [
          %{
            name: "Empty",
            value: "You have no items in your inventory."
          }
        ]
      else
        fields
      end

    %{
      embed: %{
        title: "Inventory",
        fields: fields
      }
    }
  end

  def send_water_update(watered_plot_items, slash_command \\ false) do
    updated_plants_string =
      Enum.map(watered_plot_items, fn watered ->
        case watered do
          {:ok, plot_item} ->
            "- Your #{Util.emoji_for_item(plot_item.item.name)} **#{plot_item.item.name}** grew"

          _ ->
            nil
        end
      end)
      |> Enum.reject(fn x -> is_nil(x) end)
      |> Enum.join("\n")
      |> String.replace_leading("- ", "\n- ")

    updated_plants_string =
      if updated_plants_string == "" do
        "You watered your plants, but none of them grew."
      else
        "Your plants have been watered!#{updated_plants_string}"
      end

    data = %{
      content:
        "#{updated_plants_string}" <>
          "\n\n*use `daf plot` to see your farm*"
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_shop(user, true = _slash_command) do
    shop_string =
      Shop.get_items()
      |> Enum.map(fn shop_item ->
        "#{Util.emoji_for_item(shop_item.name)} **#{shop_item.name}** (#{Util.format_currency(shop_item.cost)})" <>
          "\n#{shop_item.description}"
      end)
      |> Enum.join("\n\n")

    embed =
      %Nostrum.Struct.Embed{}
      |> Embed.put_title("Shop")
      |> Embed.put_color(10_212_547)
      |> Embed.put_description(
        "Use `/buy <item>` to buy an item." <>
          "\n:coin: #{Util.format_currency(user.money)}\n\n" <>
          "#{shop_string}"
      )

    %{
      type: 4,
      data: %{
        embeds: [embed]
      }
    }
  end

  def send_shop(user, false = _slash_command) do
    %{
      embed: %{
        title: "Shop",
        description:
          "Use `daf buy <item>` to buy an item." <>
            "\n:coin: #{Util.format_currency(user.money)}",
        fields:
          Shop.get_items()
          |> Enum.map(fn shop_item ->
            %{
              name: shop_item.name,
              value:
                "#{Util.emoji_for_item(shop_item.name)} Price: #{Util.format_currency(shop_item.cost)}" <>
                  "\n#{shop_item.description}"
            }
          end)
      }
    }
  end

  def send_receipt(:bought, amount, item_name, price, slash_command) do
    data = %{
      content:
        "You bought **#{amount}** #{Util.emoji_for_item(item_name)} #{item_name} for **#{Util.format_currency(price)}** coins."
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_receipt(:sold, amount, item_name, price, slash_command) do
    data = %{
      content:
        "You sold **#{amount}** #{Util.emoji_for_item(item_name)} #{item_name} for **#{Util.format_currency(price)}** coins."
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_planted(item, spot, slash_command \\ false) do
    data = %{
      content:
        "You planted #{Util.emoji_for_item(item.name)} **#{item.name}** in spot **#{spot}**."
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_plant_removed(plot_item, spot, slash_command \\ false) do
    data = %{
      content:
        "You removed #{Util.emoji_for_item(plot_item.item.name)} **#{plot_item.item.name}** from spot **#{spot}**."
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_harvest(harvest, slash_command \\ false) do
    harvest =
      harvest
      |> Enum.reject(fn x ->
        case x do
          {:error, _} -> true
          nil -> true
          _ -> false
        end
      end)

    harvest_string =
      Enum.map(harvest, fn yield ->
        case yield do
          {plot_item, :died} ->
            "- #{Util.emoji_for_item(plot_item.item.name)} **#{plot_item.item.name}** died after being harvested **#{plot_item.times_harvested} times**."

          {plot_item, yield} ->
            item_yield_string =
              yield
              |> Map.to_list()
              |> Enum.map(fn {item_name, amount} ->
                "#{amount} #{item_name}"
              end)
              |> Enum.join(", ")

            "- #{Util.emoji_for_item(plot_item.item.name)} **#{plot_item.item.name}**: " <>
              "#{item_yield_string}"

          _ ->
            nil
        end
      end)
      |> Enum.join("\n")

    data =
      if length(harvest) == 0 do
        %{
          content: "Nothing to harvest!"
        }
      else
        %{
          content:
            "Whew! Your hard work has paid off, and your harvest looks impressive:\n" <>
              "#{harvest_string}"
        }
      end

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_refill(slash_command \\ false) do
    data = %{
      content: "You refilled your water and energy. You can do this once every 30 minutes."
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_daily(message, slash_command \\ false) do
    data = %{
      content: message
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_sleep(message, slash_command \\ false) do
    data = %{
      content: message
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_error(message, slash_command \\ false) do
    data = %{
      content: message
    }

    if slash_command do
      %{
        type: 4,
        data: data
      }
    else
      data
    end
  end

  def send_rate_limited(
        message \\ "Whoa there! You're doing that too fast. Try again in a few seconds.",
        slash_command \\ false
      ) do
    if slash_command do
      %{
        type: 4,
        data: %{
          content: message
        }
      }
    else
      %{
        content: message
      }
    end
  end

  def send_help(true = _slash_command) do
    commands = [
      {"/daf", "Shows your money and stats."},
      {"/setup", "Sets up your farm."},
      {"/plot", "Shows your active plot of land."},
      {"/plant <plant> <spot>", "Plant an item in a spot. Example: `/plant strawberry_seed a4`."},
      {"/water", "Waters your plants. Requires water and energy."},
      {"/harvest", "Harvests your plants. Requires energy."},
      {"/daily", "Gives you daily rewards."},
      {"/sleep", "Take a nap for more energy. Requires a bed."},
      {"/remove <spot>", "Removes an item from a spot. Requires energy."},
      {"/info <spot>", "Shows info about a spot."},
      {"/shop", "Shows the shop."},
      {"/buy <item> [amount = 1]", "Buys an item from the shop. Example: `/buy bed`."},
      {"/sell <item> [amount = 1]", "Sells an item from your inventory."},
      {"/help", "Shows this message."}
    ]

    command_string =
      Enum.map(commands, fn {command, description} ->
        "**#{command}**\n#{description}"
      end)
      |> Enum.join("\n\n")

    embed =
      %Nostrum.Struct.Embed{}
      |> Embed.put_title("DaFarmz Guide")
      |> Embed.put_color(10_212_547)
      |> Embed.put_description(
        "DaFarmz is a game where you can grow plants and sell them for fake money." <>
          " You can also do things to make your plants grow faster." <>
          "\n\nThe game is brand new and if you'd like to pitch ideas, join the [Discord](https://discord.gg/pasxV2MTvW)!\n\n" <>
          command_string
      )

    %{
      type: 4,
      data: %{
        embeds: [embed]
      }
    }
  end

  def send_help(false = _slash_command) do
    %{
      embed: %{
        title: "DaFarmz Guide",
        description:
          "DaFarmz is a game where you can grow plants and sell them for fake money." <>
            " You can also do things to make your plants grow faster." <>
            "\n\nThe game is brand new and if you'd like to pitch ideas, join the [Discord](https://discord.gg/pasxV2MTvW)!",
        fields: [
          %{
            name: "daf",
            value: "Shows your money and stats."
          },
          %{
            name: "daf setup",
            value: "Sets up your farm."
          },
          %{
            name: "daf plot",
            value: "Shows your active plot of land."
          },
          %{
            name: "daf plant <plant> <spot>",
            value: "Plant an item in a spot. Example: `daf plant strawberry_seed a4`."
          },
          %{
            name: "daf water",
            value: "Waters your plants. Requires water and energy."
          },
          %{
            name: "daf harvest",
            value: "Harvests your plants. Requires energy."
          },
          %{
            name: "daf daily",
            value: "Gives you daily rewards."
          },
          %{
            name: "daf sleep",
            value: "Take a nap for more energy. Requires a bed."
          },
          %{
            name: "daf remove <spot>",
            value: "Removes an item from a spot. Requires energy."
          },
          %{
            name: "daf info <spot>",
            value: "Shows info about a spot."
          },
          %{
            name: "daf shop",
            value: "Shows the shop."
          },
          %{
            name: "daf buy <item> [amount = 1]",
            value: "Buys an item from the shop. Example: `daf buy bed`."
          },
          %{
            name: "daf sell <item> [amount = 1]",
            value: "Sells an item from your inventory."
          },
          %{
            name: "daf help",
            value: "Shows this message."
          }
        ]
      }
    }
  end
end
