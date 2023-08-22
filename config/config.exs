import Config

config :dafarmz_bot, ecto_repos: [DafarmzBot.Repo]

config :dafarmz_bot, DafarmzBot.Repo,
  database: "farm_game",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: [:guilds, :guild_messages, :message_content, :guild_message_reactions]

config :ex_rated,
  timeout: 90_000_000,
  cleanup_rate: 60_000,
  persistent: false,
  name: :ex_rated,
  ets_table_name: :ex_rated_buckets
