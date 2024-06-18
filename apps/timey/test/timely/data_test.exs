defmodule Timey.DataTest do
  use Timey.DataCase

  alias Timey.Data

  describe "checklist_items" do
    alias Timey.Data.Task

    import Timey.DataFixtures

    @invalid_attrs %{description: nil}

    test "list_checklist_items/0 returns all checklist_items" do
      checklist_item = checklist_item_fixture()
      assert Data.list_checklist_items() == [checklist_item]
    end

    test "get_checklist_item!/1 returns the checklist_item with given id" do
      checklist_item = checklist_item_fixture()
      assert Data.get_checklist_item!(checklist_item.id) == checklist_item
    end

    test "create_checklist_item/1 with valid data creates a checklist_item" do
      valid_attrs = %{description: "some description"}

      assert {:ok, %Task{} = checklist_item} = Data.create_checklist_item(valid_attrs)
      assert checklist_item.description == "some description"
    end

    test "create_checklist_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_checklist_item(@invalid_attrs)
    end

    test "update_checklist_item/2 with valid data updates the checklist_item" do
      checklist_item = checklist_item_fixture()
      update_attrs = %{description: "some updated description"}

      assert {:ok, %Task{} = checklist_item} = Data.update_checklist_item(checklist_item, update_attrs)
      assert checklist_item.description == "some updated description"
    end

    test "update_checklist_item/2 with invalid data returns error changeset" do
      checklist_item = checklist_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_checklist_item(checklist_item, @invalid_attrs)
      assert checklist_item == Data.get_checklist_item!(checklist_item.id)
    end

    test "delete_checklist_item/1 deletes the checklist_item" do
      checklist_item = checklist_item_fixture()
      assert {:ok, %Task{}} = Data.delete_checklist_item(checklist_item)
      assert_raise Ecto.NoResultsError, fn -> Data.get_checklist_item!(checklist_item.id) end
    end

    test "change_checklist_item/1 returns a checklist_item changeset" do
      checklist_item = checklist_item_fixture()
      assert %Ecto.Changeset{} = Data.change_checklist_item(checklist_item)
    end
  end

  describe "tasks" do
    alias Timey.Data.Task

    import Timey.DataFixtures

    @invalid_attrs %{status: nil, text: nil}

    test "list_tasks/0 returns all tasks" do
      task = task_fixture()
      assert Data.list_tasks() == [task]
    end

    test "get_task!/1 returns the task with given id" do
      task = task_fixture()
      assert Data.get_task!(task.id) == task
    end

    test "create_task/1 with valid data creates a task" do
      valid_attrs = %{status: :active, text: "some text"}

      assert {:ok, %Task{} = task} = Data.create_task(valid_attrs)
      assert task.status == :active
      assert task.text == "some text"
    end

    test "create_task/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_task(@invalid_attrs)
    end

    test "update_task/2 with valid data updates the task" do
      task = task_fixture()
      update_attrs = %{status: :complete, text: "some updated text"}

      assert {:ok, %Task{} = task} = Data.update_task(task, update_attrs)
      assert task.status == :complete
      assert task.text == "some updated text"
    end

    test "update_task/2 with invalid data returns error changeset" do
      task = task_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_task(task, @invalid_attrs)
      assert task == Data.get_task!(task.id)
    end

    test "delete_task/1 deletes the task" do
      task = task_fixture()
      assert {:ok, %Task{}} = Data.delete_task(task)
      assert_raise Ecto.NoResultsError, fn -> Data.get_task!(task.id) end
    end

    test "change_task/1 returns a task changeset" do
      task = task_fixture()
      assert %Ecto.Changeset{} = Data.change_task(task)
    end
  end

  describe "comments" do
    alias Timey.Data.Comment

    import Timey.DataFixtures

    @invalid_attrs %{comment_reason: nil, text: nil}

    test "list_comments/0 returns all comments" do
      comment = comment_fixture()
      assert Data.list_comments() == [comment]
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      assert Data.get_comment!(comment.id) == comment
    end

    test "create_comment/1 with valid data creates a comment" do
      valid_attrs = %{comment_reason: :justify_ignored, text: "some text"}

      assert {:ok, %Comment{} = comment} = Data.create_comment(valid_attrs)
      assert comment.comment_reason == :justify_ignored
      assert comment.text == "some text"
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_comment(@invalid_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      update_attrs = %{comment_reason: :more_info, text: "some updated text"}

      assert {:ok, %Comment{} = comment} = Data.update_comment(comment, update_attrs)
      assert comment.comment_reason == :more_info
      assert comment.text == "some updated text"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_comment(comment, @invalid_attrs)
      assert comment == Data.get_comment!(comment.id)
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Data.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Data.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Data.change_comment(comment)
    end
  end
end
