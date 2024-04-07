defmodule TimelyWeb.ChecklistItemController do
  use TimelyWeb, :controller

  alias Timely.Data
  alias Timely.Data.ChecklistItem

  action_fallback TimelyWeb.FallbackController

  def index(conn, _params) do
    checklist_items = Data.list_checklist_items()
    render(conn, :index, checklist_items: checklist_items)
  end

  def create(conn, %{"checklist_item" => checklist_item_params}) do
    with {:ok, %ChecklistItem{} = checklist_item} <- Data.create_checklist_item(checklist_item_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/checklist_items/#{checklist_item}")
      |> render(:show, checklist_item: checklist_item)
    end
  end

  def show(conn, %{"id" => id}) do
    checklist_item = Data.get_checklist_item!(id)
    render(conn, :show, checklist_item: checklist_item)
  end

  def update(conn, %{"id" => id, "checklist_item" => checklist_item_params}) do
    checklist_item = Data.get_checklist_item!(id)

    with {:ok, %ChecklistItem{} = checklist_item} <- Data.update_checklist_item(checklist_item, checklist_item_params) do
      render(conn, :show, checklist_item: checklist_item)
    end
  end

  def delete(conn, %{"id" => id}) do
    checklist_item = Data.get_checklist_item!(id)

    with {:ok, %ChecklistItem{}} <- Data.delete_checklist_item(checklist_item) do
      send_resp(conn, :no_content, "")
    end
  end
end
