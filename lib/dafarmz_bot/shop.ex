defmodule DafarmzBot.Shop do
  alias DafarmzBot.{Repo, User, Item}
  import Ecto.Query

  def buy_item(user_id, item_id, amount \\ 1) do
    item = Repo.get(Item, item_id)
    price = item.cost * amount

    user = Repo.get(User, user_id)
    money = user.money

    if money >= price do
      inventory = user.inventory

      if item.item_type == "one_time" and Map.get(inventory, item.name, 0) > 0 do
        {:error, "You already have **#{item.name}**! This item is a one time purchase."}
      else
        inventory = Map.put(inventory, item.name, Map.get(inventory, item.name, 0) + amount)

        user
        |> User.changeset(%{money: money - price, inventory: inventory})
        |> Repo.update()

        {:ok, amount, item.name, price}
      end
    else
      {:error,
       "You don't have enough for #{amount}x #{Util.emoji_for_item(item.name)} **#{item.name}**!"}
    end
  end

  def sell_item(user, item, amount) when is_binary(amount) do
    amount =
      if String.downcase(amount) == "a" do
        Map.get(user.inventory, item.name, 0)
      else
        {parsed, _} = Integer.parse(amount)
        parsed
      end

    sell_item(user, item, amount)
  end

  def sell_item(user, item, amount) when is_integer(amount) do
    price_per_unit = max(1, trunc(item.cost * 0.05))
    price = price_per_unit * amount

    inventory = user.inventory
    inv_amount = Map.get(inventory, item.name, 0)

    if inv_amount < amount or inv_amount == 0 do
      {:error, "You don't have enough #{Util.emoji_for_item(item.name)} **#{item.name}**!"}
    else
      if item.item_type == "one_time" do
        {:error, "You can't sell **#{item.name}**! Sorry bout that..."}
      else
        inventory = Map.put(inventory, item.name, inv_amount - amount)

        user
        |> User.changeset(%{money: user.money + price, inventory: inventory})
        |> Repo.update()

        {:ok, amount, item.name, price}
      end
    end
  end

  def get_item_by_id(id) do
    Repo.get(Item, id)
  end

  def get_items() do
    Repo.all(
      from(i in Item,
        where: not is_nil(i.lifecycle_images) or i.item_type == "one_time",
        select: i
      )
    )
  end

  def get_item_by_name(nil), do: nil

  def get_item_by_name(name) do
    query =
      from(i in Item,
        where: i.name == ^name,
        select: i
      )

    Repo.one(query)
  end
end
