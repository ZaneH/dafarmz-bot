defmodule DafarmzBot.Controllers.ShopController do
  alias DafarmzBot.{Users, Shop}

  def send_shop(author_id, slash_command \\ false) do
    case ExRated.check_rate("shop-#{author_id}", 10_000, 3) do
      {:ok, _} ->
        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            Responses.send_shop(user, slash_command)

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

  def buy(author_id, item, amount, slash_command) do
    buy(author_id, "#{item} #{amount}", slash_command)
  end

  def buy(author_id, input, slash_command \\ true) do
    case ExRated.check_rate("buy-#{author_id}", 10_000, 4) do
      {:ok, _} ->
        matches = Regex.run(~r/(\w+)\s?(\d+)?/, input)
        destructure([_, item, amount], matches)
        amount = if is_nil(amount), do: "1", else: amount
        {amount, _} = Integer.parse(amount)

        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            case Shop.get_item_by_name(item) do
              nil ->
                Responses.send_shop(user, slash_command)

              item ->
                case Shop.buy_item(user.id, item.id, amount) do
                  {:ok, amount, item_name, price} = _ ->
                    Responses.send_receipt(
                      :bought,
                      amount,
                      item_name,
                      price,
                      slash_command
                    )

                  {:error, error} ->
                    Responses.send_error(error, slash_command)
                end
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

  def sell(author_id, item, amount, slash_command) do
    sell(author_id, "#{item} #{amount}", slash_command)
  end

  def sell(author_id, input, slash_command \\ false) do
    case ExRated.check_rate("sell-#{author_id}", 10_000, 4) do
      {:ok, _} ->
        matches = Regex.run(~r/(\w+)\s?(\d+|[Aa])?/, input)
        destructure([_, item, amount], matches)
        amount = if is_nil(amount), do: "1", else: amount

        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            case Shop.get_item_by_name(item) do
              nil ->
                Responses.send_shop(user, slash_command)

              item ->
                case Shop.sell_item(user, item, amount) do
                  {:ok, amount, item_name, price} = _ ->
                    Responses.send_receipt(:sold, amount, item_name, price, slash_command)

                  {:error, error} ->
                    Responses.send_error(error, slash_command)
                end
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
end
