defmodule TimelyWeb.ChecklistItemControllerTest do
  use TimelyWeb.ConnCase

  import Timely.DataFixtures

  alias Timely.Data.ChecklistItem

  @create_attrs %{
    description: "some description"
  }
  @update_attrs %{
    description: "some updated description"
  }
  @invalid_attrs %{description: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all checklist_items", %{conn: conn} do
      conn = get(conn, ~p"/api/checklist_items")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create checklist_item" do
    test "renders checklist_item when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/checklist_items", checklist_item: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/checklist_items/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some description"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/checklist_items", checklist_item: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update checklist_item" do
    setup [:create_checklist_item]

    test "renders checklist_item when data is valid", %{conn: conn, checklist_item: %ChecklistItem{id: id} = checklist_item} do
      conn = put(conn, ~p"/api/checklist_items/#{checklist_item}", checklist_item: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/checklist_items/#{id}")

      assert %{
               "id" => ^id,
               "description" => "some updated description"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, checklist_item: checklist_item} do
      conn = put(conn, ~p"/api/checklist_items/#{checklist_item}", checklist_item: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete checklist_item" do
    setup [:create_checklist_item]

    test "deletes chosen checklist_item", %{conn: conn, checklist_item: checklist_item} do
      conn = delete(conn, ~p"/api/checklist_items/#{checklist_item}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/checklist_items/#{checklist_item}")
      end
    end
  end

  defp create_checklist_item(_) do
    checklist_item = checklist_item_fixture()
    %{checklist_item: checklist_item}
  end
end
