defmodule IdPrefixApp do
  @moduledoc """
  Documentation for `IdPrefixApp`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> IdPrefixApp.hello()
      :world

  """
  use Application

  # def child_spec(opts) do
  #   %{
  #     id: __MODULE__,
  #     start: {Supervisor, :start_link, [opts]},
  #     type: :worker,
  #     restart: :permanent,
  #     shutdown: 500
  #   }
  # end

  @impl true
  def start(_type, _args) do
    children = [
      # Start Mnesia
      {Task, fn ->
        Amnesia.start()
        Amnesia.Schema.create([node()])
        # Database.create()
      end
      },
      # Start Redix
      {Redix, name: :redix},
      # Start the queue
      %{
        id: IdPrefixApp.Base36Generator,
        start: {IdPrefixApp.Base36Generator, [[]]},
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
