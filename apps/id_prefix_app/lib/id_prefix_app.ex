defmodule IdPrefixApp do
  @moduledoc """
  Documentation for `IdPrefixApp`.
  """
  use Amnesia
  require Logger
  use Application

  @impl true
  def start(_type, _args) do
    Logger.info("Starting IdPrefixApp")
    children = [
      # Start Redix
      {Redix, {"valkey://localhost:6379", [name: :redix]}},
      # {Redix, %{host: "localhost", port: 6379, name: :redix}},
      {IdPrefixApp.Database, {[], [name: IdPrefixApp.Database]}},
      {IdPrefixApp.PrefixGenerator, {:redix, IdPrefixApp.Database}}
    ]

    opts = [strategy: :rest_for_one, name: IdPrefixApp]
    Supervisor.start_link(children, opts)
  end

  def get_prefix() do
    IdPrefixApp.PrefixGenerator.get_prefix()
  end

  def mark_active(id) do
    IdPrefixApp.PrefixGenerator.mark_active(id)
  end

  def mark_used(id) do
    IdPrefixApp.PrefixGenerator.mark_used(id)
  end

  def mark_done(id) do
    IdPrefixApp.PrefixGenerator.mark_done(id)
  end

  @impl true
  def stop(_state) do
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
