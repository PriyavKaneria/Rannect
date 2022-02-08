defmodule Rannect.RannectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rannect.Rannections` context.
  """

  # @doc """
  # Generate a rannection.
  # """
  # def rannection_fixture(attrs \\ %{}) do
  #   {:ok, rannection} =
  #     attrs
  #     |> Enum.into(%{
  #       blocked: true,
  #     })
  #     |> Rannect.Rannections.create_rannection()

  #   rannection
  # end

  @doc """
  Generate a chat.
  """
  def chat_fixture(attrs \\ %{}) do
    {:ok, chat} =
      attrs
      |> Enum.into(%{
        img_url: "some img_url",
        message: "some message"
      })
      |> Rannect.Rannections.create_chat()

    chat
  end
end
