defmodule IdPrefixApp.Bag do
  use Amnesia
  use Amnesia.Table, attributes: [:value]

  def start_link(_args) do
    Amnesia.Table.create(__MODULE__, [:value], type: :set, disc_copies: [node()])
    {:ok, %{}}
  end

  def stop() do
  end

  def put(value) do
    Amnesia.transaction do
      %IdPrefixApp.Bag{value: value}
      |> IdPrefixApp.Bag.write()
    end
  end

  def get() do
    Amnesia.transaction do
      case IdPrefixApp.Bag.first() do
        nil -> {:error, :empty}
        value ->
          IdPrefixApp.Bag.delete(value)
          {:ok, value.value}
      end
    end
  end

  def is_empty() do
    Amnesia.transaction do
      QueueApp.Queue.first() == nil
    end
  end
end
