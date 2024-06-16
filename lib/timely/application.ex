defmodule Timely.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TimelyWeb.Telemetry,
      Timely.Repo,
      {DNSCluster, query: Application.get_env(:timely, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Timely.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Timely.Finch},
      # Start a worker by calling: Timely.Worker.start_link(arg)
      # {Timely.Worker, arg},
      # Start to serve requests, typically the last entry
      TimelyWeb.Endpoint,
      IdPrefixApp
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Timely.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TimelyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
