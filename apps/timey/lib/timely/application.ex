defmodule Timey.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TimeyWeb.Telemetry,
      Timey.Repo,
      {DNSCluster, query: Application.get_env(:timey, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Timey.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Timey.Finch},
      # Start a worker by calling: Timey.Worker.start_link(arg)
      # {Timey.Worker, arg},
      # Start to serve requests, typically the last entry
      TimeyWeb.Endpoint,
      IdPrefixApp
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Timey.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TimeyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
