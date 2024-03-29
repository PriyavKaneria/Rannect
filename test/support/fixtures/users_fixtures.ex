defmodule Rannect.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Rannect.Users` context.
  """

  alias Rannect.Repo
  alias Rannect.Users.{User, UserToken}

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"
  def unique_user_username, do: "user#{System.unique_integer()}"

  def valid_user_attributes(attrs \\ %{}) do
    newAttr =
      Enum.into(attrs, %{
        email: unique_user_email(),
        password: valid_user_password()
      })

    newAttr =
      Map.merge(newAttr, %{
        username: unique_user_username(),
        age: 18
      })

    newAttr
  end

  def user_fixture(attrs \\ %{}, opts \\ []) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Rannect.Users.register_user()

    if Keyword.get(opts, :confirmed, true), do: Repo.transaction(confirm_user_multi(user))
    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end
end
