defmodule MessageConsumer do
  use Nostrum.Consumer
  alias Nostrum.Api
  alias Nostrum.Struct.Interaction
  alias DafarmzBot.Controllers

  def handle_event({:READY, ready, _ws_state}) do
    guilds = ready.guilds

    commands = [
      %{name: "daf", description: "View your DaFarmz info"},
      %{name: "balance", description: "View your balance"},
      %{name: "inventory", description: "View your inventory"},
      %{
        name: "info",
        description: "View your info",
        options: [
          %{
            name: "spot",
            description: "The spot you want to view",
            type: 3
          }
        ]
      },
      %{name: "shop", description: "View the shop"},
      %{
        name: "plot",
        description: "View your farm plot"
      },
      %{
        name: "setup",
        description: "Start your farm"
      },
      %{
        name: "refill",
        description: "Refill your energy"
      },
      %{
        name: "water",
        description: "Water your crops"
      },
      %{
        name: "plant",
        description: "Plant a crop",
        options: [
          %{
            name: "item",
            description: "The item you want to plant",
            type: 3
          },
          %{
            name: "spot",
            description: "The spot you want to plant in",
            type: 3
          }
        ]
      },
      %{
        name: "remove",
        description: "Remove a crop",
        options: [
          %{
            name: "spot",
            description: "The spot you want to remove",
            type: 3
          }
        ]
      },
      %{
        name: "buy",
        description: "Buy an item",
        options: [
          %{
            name: "item",
            description: "The item you want to buy",
            type: 3
          },
          %{
            name: "amount",
            description: "The amount you want to buy",
            type: 3
          }
        ]
      },
      %{
        name: "sell",
        description: "Sell an item",
        options: [
          %{
            name: "item",
            description: "The item you want to sell",
            type: 3
          },
          %{
            name: "amount",
            description: "The amount you want to sell",
            type: 3
          }
        ]
      },
      %{
        name: "harvest",
        description: "Harvest your crops"
      },
      %{
        name: "sleep",
        description: "Sleep for the night"
      },
      %{
        name: "daily",
        description: "Claim your daily reward"
      },
      %{
        name: "help",
        description: "View the help menu"
      }
    ]

    for guild <- guilds do
      Enum.each(commands, fn command ->
        Nostrum.Api.create_guild_application_command(guild.id, command)
      end)
    end
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{data: %{name: name, options: options}} = interaction,
         _ws_state}
      ) do
    options = if is_nil(options), do: [], else: options

    case name do
      "daf" ->
        Api.create_interaction_response(
          interaction,
          Controllers.UserController.info(interaction.member.user_id, true)
        )

      "balance" ->
        Api.create_interaction_response(
          interaction,
          Controllers.UserController.balance(interaction.member.user_id, true)
        )

      "setup" ->
        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.setup(interaction.member.user_id, true)
        )

      "inventory" ->
        Api.create_interaction_response(
          interaction,
          Controllers.UserController.inventory(interaction.member.user_id, true)
        )

      "plot" ->
        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.plot(interaction.member.user_id, true)
        )

      "refill" ->
        Api.create_interaction_response(
          interaction,
          Controllers.UserController.refill(interaction.member.user_id, true)
        )

      "water" ->
        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.water(interaction.member.user_id, true)
        )

      "plant" ->
        item = Enum.find(options, &(&1.name == "item")) || %{}
        spot = Enum.find(options, &(&1.name == "spot")) || %{}

        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.plant(
            interaction.member.user_id,
            Map.get(item, :value),
            Map.get(spot, :value),
            true
          )
        )

      "remove" ->
        spot = Enum.find(options, &(&1.name == "spot")) || %{}

        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.remove(
            interaction.member.user_id,
            "#{Map.get(spot, :value)}",
            true
          )
        )

      "buy" ->
        item = Enum.find(options, &(&1.name == "item")) || %{}
        amount = Enum.find(options, &(&1.name == "amount")) || %{}

        Api.create_interaction_response(
          interaction,
          Controllers.ShopController.buy(
            interaction.member.user_id,
            Map.get(item, :value),
            Map.get(amount, :value),
            true
          )
        )

      "sell" ->
        item = Enum.find(options, &(&1.name == "item")) || %{}
        amount = Enum.find(options, &(&1.name == "amount")) || %{}

        Api.create_interaction_response(
          interaction,
          Controllers.ShopController.sell(
            interaction.member.user_id,
            Map.get(item, :value),
            Map.get(amount, :value),
            true
          )
        )

      "sleep" ->
        Api.create_interaction_response(
          interaction,
          Controllers.UserController.sleep(interaction.member.user_id, true)
        )

      "shop" ->
        Api.create_interaction_response(
          interaction,
          Controllers.ShopController.send_shop(interaction.member.user_id, true)
        )

      "info" ->
        spot = Enum.find(options, &(&1.name == "spot")) || %{}

        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.info(
            interaction.member.user_id,
            Map.get(spot, :value, ""),
            true
          )
        )

      "harvest" ->
        Api.create_interaction_response(
          interaction,
          Controllers.PlotController.harvest(interaction.member.user_id, true)
        )

      "daily" ->
        Api.create_interaction_response(
          interaction,
          Controllers.UserController.daily(interaction.member.user_id, true)
        )

      "help" ->
        Api.create_interaction_response(
          interaction,
          Responses.send_help(true)
        )
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content |> String.downcase() do
      "daf" ->
        Api.create_message(
          msg.channel_id,
          Controllers.UserController.info(msg.author.id, false)
        )

      "daf bal" ->
        Api.create_message(
          msg.channel_id,
          Controllers.UserController.balance(msg.author.id, false)
        )

      "daf setup" ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.setup(msg.author.id, false)
        )

      "daf inv" <> _ ->
        Api.create_message(
          msg.channel_id,
          Controllers.UserController.inventory(msg.author.id, false)
        )

      "daf help" ->
        Api.create_message(
          msg.channel_id,
          Responses.send_help(false)
        )

      "daf plot" ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.plot(msg.author.id, false)
        )

      "daf info" ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.info(msg.author.id, "", false)
        )

      "daf info " <> rest ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.info(
            msg.author.id,
            rest,
            false
          )
        )

      "daf refill" ->
        Api.create_message(
          msg.channel_id,
          Controllers.UserController.refill(msg.author.id, false)
        )

      "daf water" ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.water(msg.author.id, false)
        )

      "daf shop" ->
        Api.create_message(
          msg.channel_id,
          Controllers.ShopController.send_shop(msg.author.id, false)
        )

      "daf buy " <> rest ->
        Api.create_message(
          msg.channel_id,
          Controllers.ShopController.buy(msg.author.id, rest, false)
        )

      "daf sell " <> rest ->
        Api.create_message(
          msg.channel_id,
          Controllers.ShopController.sell(msg.author.id, rest, false)
        )

      "daf buy" ->
        Api.create_message(
          msg.channel_id,
          Controllers.ShopController.send_shop(msg.author.id, false)
        )

      "daf plant" ->
        Api.create_message(
          msg.channel_id,
          Responses.send_error(
            "You need to specify an item and a spot to plant!\nExample: `daf plant strawberry A1`",
            false
          )
        )

      "daf plant " <> rest ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.plant(msg.author.id, rest, false)
        )

      "daf remove" <> rest ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.remove(msg.author.id, rest, false)
        )

      "daf harvest" ->
        Api.create_message(
          msg.channel_id,
          Controllers.PlotController.harvest(msg.author.id, false)
        )

      "daf daily" ->
        Api.create_message(
          msg.channel_id,
          Controllers.UserController.daily(msg.author.id, false)
        )

      "daf sleep" ->
        Api.create_message(
          msg.channel_id,
          Controllers.UserController.sleep(msg.author.id, false)
        )

      _ ->
        :ignore
    end
  end

  def handle_event(_) do
    :ignore
  end
end
