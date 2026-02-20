defmodule Mana.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      ManaWeb.Telemetry,
      Mana.Repo,
      {DNSCluster, query: Application.get_env(:mana, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mana.PubSub},
      Mana.Sense.Vereis,
      # Start a worker by calling: Mana.Worker.start_link(arg)
      # {Mana.Worker, arg},
      # Start to serve requests, typically the last entry
      ManaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mana.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    ManaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
