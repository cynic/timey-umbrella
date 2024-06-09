defmodule TimelyWeb.TaskJSON do
  alias Timely.Data.Task

  @doc """
  Renders a list of tasks.
  """
  def index(%{tasks: tasks}) do
    %{data: for(task <- tasks, do: data(task))}
  end

  @doc """
  Renders a single task.
  """
  def show(%{task: task}) do
    %{data: data(task)}
  end

  defp data(%Task{} = task) do
    %{
      id: task.id,
      text: task.text,
      status: task.status,
      created: DateTime.to_unix(task.inserted_at, :millisecond)
    }
  end
end
