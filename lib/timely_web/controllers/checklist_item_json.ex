defmodule TimelyWeb.ChecklistItemJSON do
  alias Timely.Data.ChecklistItem

  @doc """
  Renders a list of checklist_items.
  """
  def index(%{checklist_items: checklist_items}) do
    %{data: for(checklist_item <- checklist_items, do: data(checklist_item))}
  end

  @doc """
  Renders a single checklist_item.
  """
  def show(%{checklist_item: checklist_item}) do
    %{data: data(checklist_item)}
  end

  defp data(%ChecklistItem{} = checklist_item) do
    %{
      id: checklist_item.id,
      description: checklist_item.description,
      created: DateTime.to_unix(checklist_item.inserted_at, :millisecond)
    }
  end
end
