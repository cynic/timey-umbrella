defmodule Timely.DataFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Timely.Data` context.
  """

  @doc """
  Generate a checklist_item.
  """
  def checklist_item_fixture(attrs \\ %{}) do
    {:ok, checklist_item} =
      attrs
      |> Enum.into(%{
        description: "some description"
      })
      |> Timely.Data.create_checklist_item()

    checklist_item
  end
end
