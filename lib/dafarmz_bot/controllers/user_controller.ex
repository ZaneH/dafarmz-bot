defmodule DafarmzBot.Controllers.UserController do
  alias DafarmzBot.Users

  def info(author_id, slash_command \\ true) do
    case Users.get_by_discord_id(to_string(author_id)) do
      {:ok, user} ->
        Responses.send_user(user, slash_command)

      _ ->
        Responses.send_setup_message(slash_command)
    end
  end

  def balance(author_id, slash_command \\ true) do
    case Users.get_by_discord_id(to_string(author_id)) do
      {:ok, user} ->
        Responses.send_user(user, slash_command)

      _ ->
        Responses.send_setup_message(slash_command)
    end
  end

  def inventory(author_id, slash_command \\ true) do
    case ExRated.check_rate("inv-#{author_id}", 10_000, 4) do
      {:ok, _} ->
        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            if slash_command do
              Responses.send_inventory(user, true)
            else
              Responses.send_inventory(user)
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

  def refill(author_id, slash_command \\ true) do
    case ExRated.check_rate("refill-#{author_id}", 60_000, 4) do
      {:ok, _} ->
        case Users.get_by_discord_id(to_string(author_id)) do
          {:ok, user} ->
            case Users.refill_energy(user) do
              {:error, error} ->
                Responses.send_error(error, slash_command)

              {:ok, _} ->
                Responses.send_refill(slash_command)
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

  def sleep(author_id, slash_command \\ true) do
    case Users.get_by_discord_id(to_string(author_id)) do
      {:ok, user} ->
        case Users.sleep(user) do
          {:ok, message} ->
            Responses.send_sleep(message, slash_command)

          {:error, error} ->
            Responses.send_error(error, slash_command)
        end

      _ ->
        Responses.send_setup_message(slash_command)
    end
  end

  def daily(author_id, slash_command \\ true) do
    case Users.get_by_discord_id(to_string(author_id)) do
      {:ok, user} ->
        case Users.claim_daily(user) do
          {:ok, message} = _ ->
            Responses.send_daily(message, slash_command)

          {:error, error} ->
            Responses.send_error(error, slash_command)
        end

      _ ->
        Responses.send_setup_message(slash_command)
    end
  end
end
