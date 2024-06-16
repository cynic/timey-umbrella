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

  @impl true
  def start(_type, _args) do
    children = [
      # Start Mnesia
      {Task, fn ->
        :ok = Amnesia.start()
        Amnesia.Schema.create([node()])
      end},

      # Start the queue
      %{
        id: IdPrefixApp.Bag,
        start: {IdPrefixApp.Bag, :start_link, [[]]},
        type: :worker
      },

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
