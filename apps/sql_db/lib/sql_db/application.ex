defmodule SqlDb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SqlDb.Repo,
      {DNSCluster, query: Application.get_env(:sql_db, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Timey.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: SqlDb.Finch}
      # Start a worker by calling: SqlDb.Worker.start_link(arg)
      # {SqlDb.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: SqlDb.Supervisor)
  end
end
