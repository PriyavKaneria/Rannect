defmodule Rannect.RannectionsTest do
  use Rannect.DataCase

  alias Rannect.Rannections

  describe "rannections" do
    alias Rannect.Rannections.Rannection

    import Rannect.RannectionsFixtures

    @invalid_attrs %{blocked: nil}

    test "list_rannections/0 returns all rannections" do
      rannection = rannection_fixture()
      assert Rannections.list_rannections() == [rannection]
    end

    test "get_rannection!/1 returns the rannection with given id" do
      rannection = rannection_fixture()
      assert Rannections.get_rannection!(rannection.id) == rannection
    end

    test "create_rannection/1 with valid data creates a rannection" do
      valid_attrs = %{blocked: true}

      assert {:ok, %Rannection{} = rannection} = Rannections.create_rannection(valid_attrs)
      assert rannection.blocked == true
    end

    test "create_rannection/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rannections.create_rannection(@invalid_attrs)
    end

    test "update_rannection/2 with valid data updates the rannection" do
      rannection = rannection_fixture()
      update_attrs = %{blocked: false}

      assert {:ok, %Rannection{} = rannection} = Rannections.update_rannection(rannection, update_attrs)
      assert rannection.blocked == false
    end

    test "update_rannection/2 with invalid data returns error changeset" do
      rannection = rannection_fixture()
      assert {:error, %Ecto.Changeset{}} = Rannections.update_rannection(rannection, @invalid_attrs)
      assert rannection == Rannections.get_rannection!(rannection.id)
    end

    test "delete_rannection/1 deletes the rannection" do
      rannection = rannection_fixture()
      assert {:ok, %Rannection{}} = Rannections.delete_rannection(rannection)
      assert_raise Ecto.NoResultsError, fn -> Rannections.get_rannection!(rannection.id) end
    end

    test "change_rannection/1 returns a rannection changeset" do
      rannection = rannection_fixture()
      assert %Ecto.Changeset{} = Rannections.change_rannection(rannection)
    end
  end
end
