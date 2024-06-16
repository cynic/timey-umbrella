defmodule IdPrefixApp.Base36Generator do
  alias Postgrex.Extensions.Array
  def start_link(_args) do
    Amnesia.Table.create(__MODULE__, [:max], type: :set, disc_copies: [node()])
    initial_state =
      Amnesia.transaction do
        case IdPrefixApp.Base36Generator.first() do
          nil -> # No maximum stored.  We'll start with 1.
            %IdPrefixApp.Base36Generator{max: 1}
            |> IdPrefixApp.Base36Generator.write()
            1
          max ->
            max
        end
      end
    {:ok, initial_state}
  end

  def stop() do
  end

  def digits do: ~w"0 1 2 3 4 5 6 7 8 9 a b c d e f g h i j k l m n o p q r s t u v w x y z"

  def convert(n, acc) do
    if n == 0 do
      acc
    else
      quotient = div n 36
      remainder = rem n 36
      convert(quotient, Enum.fetch!(digits, remainder) <> acc)
    end
  end

  def convert(n) do
    if n == 0 do
      "0"
    else
      convert(n, "")
    end
  end

end
