defmodule DafarmzBot.Repo.Migrations.AddCooldownsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:cooldowns, :map, default: %{})
    end
  end
end
