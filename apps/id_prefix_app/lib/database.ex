defmodule IdPrefixApp.Database do
  use Amnesia
  require Logger
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defdatabase Database do
    @moduledoc false
    deftable PrefixMap, [:prefix, :user], type: :set, disc_only_copies: [node()] do
      @moduledoc false
      @type t :: %PrefixMap{prefix: String.t, user: integer}
    end
  end


  @impl true
  def init(_) do
    Logger.info("Starting Database")
    Amnesia.start()
    Amnesia.transaction do
      Amnesia.Schema.create([node()])
      Database.PrefixMap.create()
    end
    {:ok, nil}
  end

  @impl true
  def terminate(reason, _state) do
    Amnesia.stop()
    Logger.info("Stopping Database, reason=#{inspect(reason)}")
  end

end
