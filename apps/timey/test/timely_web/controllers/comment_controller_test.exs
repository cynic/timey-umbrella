defmodule TimeyWeb.CommentControllerTest do
  use TimeyWeb.ConnCase

  import Timey.DataFixtures

  alias Timey.Data.Comment

  @create_attrs %{
    comment_reason: :justify_ignored,
    text: "some text"
  }
  @update_attrs %{
    comment_reason: :more_info,
    text: "some updated text"
  }
  @invalid_attrs %{comment_reason: nil, text: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all comments", %{conn: conn} do
      conn = get(conn, ~p"/api/comments")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create comment" do
    test "renders comment when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/comments", comment: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/comments/#{id}")

      assert %{
               "id" => ^id,
               "comment_reason" => "justify_ignored",
               "text" => "some text"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/comments", comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update comment" do
    setup [:create_comment]

    test "renders comment when data is valid", %{conn: conn, comment: %Comment{id: id} = comment} do
      conn = put(conn, ~p"/api/comments/#{comment}", comment: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/comments/#{id}")

      assert %{
               "id" => ^id,
               "comment_reason" => "more_info",
               "text" => "some updated text"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, comment: comment} do
      conn = put(conn, ~p"/api/comments/#{comment}", comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete comment" do
    setup [:create_comment]

    test "deletes chosen comment", %{conn: conn, comment: comment} do
      conn = delete(conn, ~p"/api/comments/#{comment}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/comments/#{comment}")
      end
    end
  end

  defp create_comment(_) do
    comment = comment_fixture()
    %{comment: comment}
  end
end
