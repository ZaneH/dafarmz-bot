defmodule DafarmzBot.Repo do
  use Ecto.Repo,
    otp_app: :dafarmz_bot,
    adapter: Ecto.Adapters.Postgres
end
