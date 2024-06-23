defmodule IdPrefixApp.Base36Generator do
  use Amnesia
  require Exquisite
  require Database.PrefixMap
  require Logger

  alias Database.PrefixMap

  def start_link(_args) do
    # Amnesia.Table.create(__MODULE__, [:max], type: :set, disc_copies: [node()])
    Logger.info("Starting Base36Generator")
    case Redix.command(:redix, ~w"GET max") do
      {:ok, nil} -> # No maximum stored.  We'll start with 1.
        Redix.command!(:redix, ~w"SET max #{int_to_base36(1)}")
        {:ok, self()}
      {:ok, _} ->
        {:ok, self()}
      x ->
        x
    end
  end

  def stop() do
  end

  defp digits, do: ~w"0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z"

  defp int_to_base36(n, acc) do
    if n == 0 do
      acc
    else
      quotient = div(n, 36)
      remainder = rem(n, 36)
      int_to_base36(quotient, Enum.fetch!(digits(), remainder) <> acc)
    end
  end

  defp int_to_base36(n) when n >= 0 do
    if n <= 0 do
      "0"
    else
      int_to_base36(n, "")
    end
  end

  def get_id() do
    case Redix.command(:redix, ~w"SPOP unused-ids") do
      {:ok, nil} ->
        # We don't have any unused IDs.
        max = Redix.command!(:redix, ~w"GET max")
        v = Redix.command!(:redix, ~w"INCR max")
        Logger.debug("Post-increment: #{v}")
        {n, _} = Integer.parse(max)
        Logger.debug("Parsed: #{n}")
        output = int_to_base36(n)
        Redix.command!(:redix, ~w"SADD unsure-ids #{output}")
        Logger.debug("Output stored: #{output}")
        output
      {:ok, value} ->
        value
    end
  end

  def prefix_dropped(prefix) do
    case Redix.command(:redix, ~w"SISMEMBER unsure-ids #{prefix}") do
      {:ok, "1"} ->
        Redix.command!(:redix, ~w"SREM unsure-ids #{prefix}")
        Redix.command!(:redix, ~w"SADD unused-ids #{prefix}")
      _ ->
        # It was already removed, and that's fine.
        :ok
    end
  end

  def prefix_used(prefix, userid) do
    case Redix.command(:redix, ~w"SREM unsure-ids #{prefix}") do
      {:ok, "1"} ->
        Amnesia.transaction do
          %PrefixMap{prefix: prefix, user: userid}
          |> PrefixMap.write()
        end
      _ ->
        :ok
    end
  end

  def prefix_to_userid(prefix) do
    case PrefixMap.read(PrefixMap, prefix) do
      %PrefixMap{:user => u} ->
        {:ok, u}
      _ ->
        {:error, "Prefix #{prefix} not found"}
    end
  end

end
