defmodule Rannect.RannectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rannect.Rannections` context.
  """

  @doc """
  Generate a rannection.
  """
  def rannection_fixture(attrs \\ %{}) do
    {:ok, rannection} =
      attrs
      |> Enum.into(%{
        blocked: true
      })
      |> Rannect.Rannections.create_rannection()

    rannection
  end
end
