defmodule Timely.DataTest do
  use Timely.DataCase

  alias Timely.Data

  describe "checklist_items" do
    alias Timely.Data.ChecklistItem

    import Timely.DataFixtures

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

      assert {:ok, %ChecklistItem{} = checklist_item} = Data.create_checklist_item(valid_attrs)
      assert checklist_item.description == "some description"
    end

    test "create_checklist_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Data.create_checklist_item(@invalid_attrs)
    end

    test "update_checklist_item/2 with valid data updates the checklist_item" do
      checklist_item = checklist_item_fixture()
      update_attrs = %{description: "some updated description"}

      assert {:ok, %ChecklistItem{} = checklist_item} = Data.update_checklist_item(checklist_item, update_attrs)
      assert checklist_item.description == "some updated description"
    end

    test "update_checklist_item/2 with invalid data returns error changeset" do
      checklist_item = checklist_item_fixture()
      assert {:error, %Ecto.Changeset{}} = Data.update_checklist_item(checklist_item, @invalid_attrs)
      assert checklist_item == Data.get_checklist_item!(checklist_item.id)
    end

    test "delete_checklist_item/1 deletes the checklist_item" do
      checklist_item = checklist_item_fixture()
      assert {:ok, %ChecklistItem{}} = Data.delete_checklist_item(checklist_item)
      assert_raise Ecto.NoResultsError, fn -> Data.get_checklist_item!(checklist_item.id) end
    end

    test "change_checklist_item/1 returns a checklist_item changeset" do
      checklist_item = checklist_item_fixture()
      assert %Ecto.Changeset{} = Data.change_checklist_item(checklist_item)
    end
  end
end
