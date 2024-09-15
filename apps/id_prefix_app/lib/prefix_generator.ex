defmodule IdPrefixApp.PrefixGenerator do
  use Amnesia
  require Exquisite
  require Logger
  use GenServer

  def start_link({redix, db}) do
    GenServer.start_link(__MODULE__, {redix, db}, name: __MODULE__)
  end

  @impl true
  def init({redix, db}) do
    # Amnesia.Table.create(__MODULE__, [:max], type: :set, disc_copies: [node()])
    Logger.info("Starting PrefixGenerator")
    # The maximum is the largest number that we have tried to issue.
    # When someone asks for a prefix, and we don't have one in the
    # queue, we'll issue a conversion of `max` and then bump `max`.
    case Redix.command(redix, ~w"GET max") do
      {:ok, nil} -> # No maximum stored.  We'll start with 1.
        Redix.command!(redix, ~w"SET max 1")
        {:ok, {redix, db, 1}}
      {:ok, s} ->
        case Integer.parse(s) do
          {n, _} ->
            {:ok, {redix, db, n}}
          :error ->
            Redix.command!(:redix, ~w"SET max 1")
            {:ok, {redix, db, 1}}
          end
    end
  end

  @impl true
  def terminate(reason, _state) do
    Logger.info("Stopping PrefixGenerator, reason=#{inspect(reason)}")
  end

  @digits ~w"0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z - _ , . ~ : +"
  @base length(@digits)

  defp int_to_base(n, acc) do
    if n == 0 do
      acc
    else
      quotient = div(n, @base)
      remainder = rem(n, @base)
      int_to_base(quotient, Enum.fetch!(@digits, remainder) <> acc)
    end
  end

  defp int_to_base(n) when n >= 1 do
    int_to_base(n, "")
  end

  def get_prefix() do
    GenServer.call(__MODULE__, :get_prefix)
  end

  def mark_active(id) do
    GenServer.call(__MODULE__, {:mark_active, id})
  end

  def mark_used(id) do
    GenServer.cast(__MODULE__, {:mark_used, id})
  end

  def mark_done(id) do
    GenServer.cast(__MODULE__, {:mark_done, id})
  end

  # If the ID is not taken up after 65 seconds, we'll
  # mark it as unused.
  defp return_prefix(prefix, {redix, db, max}) do
    Redix.command!(redix, ~w"SADD transit-ids #{prefix}")
    Process.send_after(self(), {:mark_unused, prefix}, 65_000)
    {:reply, prefix, {redix, db, max}}
  end

  @impl true
  def handle_call(:get_prefix, _from, {redix, db, max}) do
    case Redix.command(redix, ~w"LPOP unused-ids") do
      {:ok, nil} -> # We don't have any unused IDs.
        new_max = Redix.command!(redix, ~w"INCR max")
        return_prefix(int_to_base(max), {redix, db, new_max})
      {:ok, value} ->
        return_prefix(value, {redix, db, max})
    end
  end

  @impl true
  def handle_call({:mark_active, id}, _from, {redix, db, max}) do
    case Redix.command(redix, ~w"SMOVE transit-ids active-ids #{id}") do
      {:ok, 1} ->
        {:reply, :ok, {redix, db, max}}
      {:ok, 0} ->
        {:reply, {:error, "Specified id #{id} was not found."}, {redix, db, max}}
    end
  end

  @impl true
  def handle_cast({:mark_used, id}, {redix, db, max}) do
    Redix.command(redix, ~w"SMOVE active-ids used-ids #{id}")
    {:noreply, {redix, db, max}}
  end

  @impl true
  def handle_cast({:mark_done, id}, {redix, db, max}) do
    if Redix.command(redix, ~w"SREM active-ids #{id}") == {:ok, 1} do
      Redix.command(redix, ~w"RPUSH unused-ids #{id}")
    end
    {:noreply, {redix, db, max}}
  end

  @impl true
  def handle_info({:mark_unused, id}, {redix, db, max}) do
    if Redix.command(redix, ~w"SREM transit-ids #{id}") == {:ok, 1} do
      Redix.command(redix, ~w"RPUSH unused-ids #{id}")
    end
    {:noreply, {redix, db, max}}
  end

end
