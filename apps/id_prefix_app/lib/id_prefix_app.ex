defmodule IdPrefixApp do
  @moduledoc """
  Documentation for `IdPrefixApp`.
  """
  require Logger

  @doc """
  Hello world.

  ## Examples

      iex> IdPrefixApp.hello()
      :world

  """
  use Application

  @impl true
  def start(_type, _args) do
    Logger.info("Starting IdPrefixApp")
    children = [
      # Start Mnesia
      {Task, fn ->
        Amnesia.start()
        Amnesia.Schema.create([node()])
        # Database.create()
      end
      },
      # Start Redix
      {Redix, {"redis://localhost:6379", [name: :redix]}},
      # {Redix, %{host: "localhost", port: 6379, name: :redix}},
      # Start the queue
      %{id: IdPrefixApp.Base36Generator,
        start: {IdPrefixApp.Base36Generator, :start_link, [[]]},
        type: :worker
      }
    ]

    opts = [strategy: :one_for_one, name: IdPrefixApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    Amnesia.stop()
    :ok
  end

end
