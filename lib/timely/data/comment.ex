defmodule Timely.Data.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :comment_reason, Ecto.Enum, values: [:justify_ignored, :more_info]
    field :text, :string
    belongs_to :task, Timely.Data.Task

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:text, :comment_reason])
    |> validate_required([:text, :comment_reason])
  end
end
