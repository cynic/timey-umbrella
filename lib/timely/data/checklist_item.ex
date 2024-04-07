defmodule Timely.Data.ChecklistItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "checklist_items" do
    field :description, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(checklist_item, attrs) do
    checklist_item
    |> cast(attrs, [:description])
    |> validate_required([:description])
  end
end
