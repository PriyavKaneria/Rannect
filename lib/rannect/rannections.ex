defmodule Rannect.Rannections do
  @moduledoc """
  The Rannections context.
  """

  import Ecto.Query, warn: false
  alias Rannect.Repo

  alias Rannect.Rannections.Rannection
  alias Rannect.Users

  @doc """
  Gets a single rannection.

  Raises `Ecto.NoResultsError` if the Rannection does not exist.

  ## Examples

      iex> get_rannection!(123)
      %Rannection{}

      iex> get_rannection!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rannection!(id), do: Repo.get!(Rannection, id)

  @doc """
  Gets user rannections.

  ## Examples

      iex> get_user_rannections(123)
      %Rannection{}

      iex> get_user_rannections(456)
      %Rannection{}

  """
  def get_rannections_users(rannections, userid) do
    users =
      for rannection <- rannections do
        rann = get_rannection!(rannection)
        cond do
          rann.invitee == userid -> rann.inviter
          rann.inviter == userid -> rann.invitee
        end
      end
    IO.inspect(users)
    users
  end

  @doc """
  Creates a rannection.

  ## Examples

      iex> create_rannection(%{field: value})
      {:ok, %Rannection{}}

      iex> create_rannection(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rannection(attrs \\ %{}) do
    inviter = attrs[:inviter]
    invitee = attrs[:invitee]

    {:ok, rannection_data} =
      %Rannection{
        blocked: false
      }
      |> Rannection.changeset(attrs)
      |> Repo.insert()

    rannection_data_map = Map.from_struct(rannection_data)

    Users.add_rannection(inviter, rannection_data_map[:id])
    Users.add_rannection(invitee, rannection_data_map[:id])
    rannection_data
  end

  @doc """
  Updates a rannection.

  ## Examples

      iex> update_rannection(rannection, %{field: new_value})
      {:ok, %Rannection{}}

      iex> update_rannection(rannection, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rannection(%Rannection{} = rannection, attrs) do
    rannection
    |> Rannection.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a rannection.

  ## Examples

      iex> delete_rannection(rannection)
      {:ok, %Rannection{}}

      iex> delete_rannection(rannection)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rannection(%Rannection{} = rannection) do
    Repo.delete(rannection)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rannection changes.

  ## Examples

      iex> change_rannection(rannection)
      %Ecto.Changeset{data: %Rannection{}}

  """
  def change_rannection(%Rannection{} = rannection, attrs \\ %{}) do
    Rannection.changeset(rannection, attrs)
  end
end
