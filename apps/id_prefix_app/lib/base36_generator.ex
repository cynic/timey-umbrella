defmodule IdPrefixApp.Base36Generator do
  require Amnesia
  require Amnesia.Helper
  require Exquisite
  require Database.PrefixMap

  alias Database.PrefixMap

  def start_link(_args) do
    # Amnesia.Table.create(__MODULE__, [:max], type: :set, disc_copies: [node()])
    initial_state =
      case Redix.command(:redix, ~w"GET max") do
        {:error, _} -> # No maximum stored.  We'll start with 1.
          initial = int_to_base36(1)
          Redix.command(:redix, ~w"SET max #{initial}")
          initial
        {:ok, max} ->
          max
      end
    {:ok, initial_state}
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
      {:error, _} ->
        # We don't have any unused IDs.
        max = Redix.command!(:redix, ~w"GET max")
        Redix.command!(:redix, ~w"INCR max")
        output = int_to_base36(max)
        Redix.command!(:redix, ~w"SADD unused-ids #{output}")
        output
      {:ok, value} ->
        value
    end
  end

  def set_used(prefix, userid) do
    case Redix.command(:redix, ~w"SREM unused-ids #{prefix}") do
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
