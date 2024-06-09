defmodule Timely.Data.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :status, Ecto.Enum, values: [:active, :complete, :ignored]
    field :text, :string
    belongs_to :user, Timely.Accounts.User, foreign_key: :user_id
    has_many :comments, Timely.Data.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:text, :status])
    |> validate_required([:text, :status])
  end
end
