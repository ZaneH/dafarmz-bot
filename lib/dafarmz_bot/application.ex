defmodule DafarmzBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MessageConsumer,
      DafarmzBot.Repo,
      %{
        id: NodeJS,
        start:
          {NodeJS, :start_link,
           [[path: System.get_env("JS_IMAGE_DIR") || "js_image", pool_size: 4]]}
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DafarmzBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
