defmodule Rannect.Rannections do
  @moduledoc """
  The Rannections context.
  """

  import Ecto.Query, warn: false
  alias Rannect.Repo

  alias Rannect.Rannections.Rannection
  alias Rannect.Users
  alias Rannect.Rannections.Chat

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
  Gets a single rannection from inviter and invitee id.
  
  Raises `Ecto.NoResultsError` if the Rannection does not exist.
  
  ## Examples
  
      iex> get_rannection_from_ids!(123, 456)
      %Rannection{}
  
      iex> get_rannection_from_ids!(123, 789)
      ** (Ecto.NoResultsError)
  
  """
  def get_rannection_from_ids!(userid1, userid2),
    do:
      Rannection
      |> where(inviter: ^userid1, invitee: ^userid2)
      |> or_where(invitee: ^userid1, inviter: ^userid2)
      |> Repo.one()

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

  @doc """
  Preloads chats for a rannection.
  
  ## Examples
  
      iex> preload_rannection_chats(rannection)
      {:ok, %Rannection{}}
  
      iex> preload_rannection_chats(rannection)
      {:error, %Ecto.Changeset{}}
  """
  def preload_rannection_chats(%Rannection{} = rannection) do
    rannection
    |> Repo.preload(:chats)
  end

  @doc """
  Returns the list of chats of rannection.
  
  ## Examples
  
      iex> list_chats(1)
      [%Chat{}, ...]
  
  """
  def list_chats(rannectionid) do
    query = from chat in Chat, where: chat.rannection_id == ^rannectionid
    Repo.all(query)
  end

  @doc """
  Gets a single chat.
  
  Raises `Ecto.NoResultsError` if the Chat does not exist.
  
  ## Examples
  
      iex> get_chat!(123)
      %Chat{}
  
      iex> get_chat!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_chat!(id), do: Repo.get!(Chat, id)

  @doc """
  Creates a chat.
  
  ## Examples
  
      iex> create_chat(%{field: value})
      {:ok, %Chat{}}
  
      iex> create_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_chat(rannection, attrs \\ %{}) do
    rannection
    |> Ecto.build_assoc(:chats)
    |> Chat.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a chat.
  
  ## Examples
  
      iex> update_chat(chat, %{field: new_value})
      {:ok, %Chat{}}
  
      iex> update_chat(chat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_chat(%Chat{} = chat, attrs) do
    chat
    |> Chat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat.
  
  ## Examples
  
      iex> delete_chat(chat)
      {:ok, %Chat{}}
  
      iex> delete_chat(chat)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_chat(%Chat{} = chat) do
    Repo.delete(chat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.
  
  ## Examples
  
      iex> change_chat(chat)
      %Ecto.Changeset{data: %Chat{}}
  
  """
  def change_chat(%Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs)
  end
end
