defmodule Timely.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :text, :string
      add :comment_reason, :string
      add :task_id, references(:tasks, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:task_id])
  end
end
