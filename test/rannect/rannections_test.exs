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

  describe "chats" do
    alias Rannect.Rannections.Chat

    import Rannect.RannectionsFixtures

    @invalid_attrs %{img_url: nil, message: nil}

    test "list_chats/0 returns all chats" do
      chat = chat_fixture()
      assert Rannections.list_chats() == [chat]
    end

    test "get_chat!/1 returns the chat with given id" do
      chat = chat_fixture()
      assert Rannections.get_chat!(chat.id) == chat
    end

    test "create_chat/1 with valid data creates a chat" do
      valid_attrs = %{img_url: "some img_url", message: "some message"}

      assert {:ok, %Chat{} = chat} = Rannections.create_chat(valid_attrs)
      assert chat.img_url == "some img_url"
      assert chat.message == "some message"
    end

    test "create_chat/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rannections.create_chat(@invalid_attrs)
    end

    test "update_chat/2 with valid data updates the chat" do
      chat = chat_fixture()
      update_attrs = %{img_url: "some updated img_url", message: "some updated message"}

      assert {:ok, %Chat{} = chat} = Rannections.update_chat(chat, update_attrs)
      assert chat.img_url == "some updated img_url"
      assert chat.message == "some updated message"
    end

    test "update_chat/2 with invalid data returns error changeset" do
      chat = chat_fixture()
      assert {:error, %Ecto.Changeset{}} = Rannections.update_chat(chat, @invalid_attrs)
      assert chat == Rannections.get_chat!(chat.id)
    end

    test "delete_chat/1 deletes the chat" do
      chat = chat_fixture()
      assert {:ok, %Chat{}} = Rannections.delete_chat(chat)
      assert_raise Ecto.NoResultsError, fn -> Rannections.get_chat!(chat.id) end
    end

    test "change_chat/1 returns a chat changeset" do
      chat = chat_fixture()
      assert %Ecto.Changeset{} = Rannections.change_chat(chat)
    end
  end
end
