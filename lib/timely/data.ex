defmodule Timely.Data do
  @moduledoc """
  The Data context.
  """

  import Ecto.Query, warn: false
  alias Timely.Repo

  alias Timely.Data.ChecklistItem

  @doc """
  Returns the list of checklist_items.

  ## Examples

      iex> list_checklist_items()
      [%ChecklistItem{}, ...]

  """
  def list_checklist_items do
    Repo.all(ChecklistItem)
  end

  @doc """
  Gets a single checklist_item.

  Raises `Ecto.NoResultsError` if the Checklist item does not exist.

  ## Examples

      iex> get_checklist_item!(123)
      %ChecklistItem{}

      iex> get_checklist_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_checklist_item!(id), do: Repo.get!(ChecklistItem, id)

  @doc """
  Creates a checklist_item.

  ## Examples

      iex> create_checklist_item(%{field: value})
      {:ok, %ChecklistItem{}}

      iex> create_checklist_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_checklist_item(attrs \\ %{}) do
    %ChecklistItem{}
    |> ChecklistItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a checklist_item.

  ## Examples

      iex> update_checklist_item(checklist_item, %{field: new_value})
      {:ok, %ChecklistItem{}}

      iex> update_checklist_item(checklist_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_checklist_item(%ChecklistItem{} = checklist_item, attrs) do
    checklist_item
    |> ChecklistItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a checklist_item.

  ## Examples

      iex> delete_checklist_item(checklist_item)
      {:ok, %ChecklistItem{}}

      iex> delete_checklist_item(checklist_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_checklist_item(%ChecklistItem{} = checklist_item) do
    Repo.delete(checklist_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking checklist_item changes.

  ## Examples

      iex> change_checklist_item(checklist_item)
      %Ecto.Changeset{data: %ChecklistItem{}}

  """
  def change_checklist_item(%ChecklistItem{} = checklist_item, attrs \\ %{}) do
    ChecklistItem.changeset(checklist_item, attrs)
  end

  alias Timely.Data.Task

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(Task)
  end

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  alias Timely.Data.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id), do: Repo.get!(Comment, id)

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end
end
