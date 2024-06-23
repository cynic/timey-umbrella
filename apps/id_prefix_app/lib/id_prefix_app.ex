defmodule IdPrefixApp do
  @moduledoc """
  Documentation for `IdPrefixApp`.
  """
  use Amnesia
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
      # Start Redix
      {Redix, {"redis://localhost:6379", [name: :redix]}},
      # {Redix, %{host: "localhost", port: 6379, name: :redix}},
      # Start the queue
      %{id: IdPrefixApp.Base36Generator,
        start: {IdPrefixApp.Base36Generator, :start_link, [[]]},
        type: :worker
      }
    ]

    Amnesia.start()
    Amnesia.transaction do
      Amnesia.Schema.create([node()])
      Database.PrefixMap.create()
    end

    opts = [strategy: :one_for_one, name: IdPrefixApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    Amnesia.stop()
    :ok
  end

  # def inspect_macros do
  #   IO.inspect(quote do
  #     use Amnesia
  #     defdatabase Database do
  #       deftable PrefixMap, [:prefix, :user], type: :set do
  #         @type t :: %PrefixMap{prefix: String.t(), user: integer()}
  #       end
  #     end
  #   end |> Macro.expand_literals(__ENV__))
  # end

end
