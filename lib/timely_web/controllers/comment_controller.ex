defmodule TimelyWeb.CommentController do
  use TimelyWeb, :controller

  alias Timely.Data
  alias Timely.Data.Comment

  action_fallback TimelyWeb.FallbackController

  def index(conn, _params) do
    comments = Data.list_comments()
    render(conn, :index, comments: comments)
  end

  def create(conn, %{"comment" => comment_params}) do
    # get the task id from the path
    task_id = conn.params["task_id"]
    # add the task id to the comment params
    comment_params = Map.put(comment_params, "task_id", task_id)
    with {:ok, %Comment{} = comment} <- Data.create_comment(comment_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/tasks/#{task_id}/comments/#{comment}")
      |> render(:show, comment: comment)
    end
  end

  def show(conn, %{"id" => id}) do
    comment = Data.get_comment!(id)
    render(conn, :show, comment: comment)
  end

  def update(conn, %{"id" => id, "comment" => comment_params}) do
    comment = Data.get_comment!(id)

    with {:ok, %Comment{} = comment} <- Data.update_comment(comment, comment_params) do
      render(conn, :show, comment: comment)
    end
  end

  def delete(conn, %{"id" => id}) do
    comment = Data.get_comment!(id)

    with {:ok, %Comment{}} <- Data.delete_comment(comment) do
      send_resp(conn, :no_content, "")
    end
  end
end
