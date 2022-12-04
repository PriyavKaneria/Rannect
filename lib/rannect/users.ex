defmodule Rannect.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Rannect.Repo

  alias Rannect.Users.{User, UserToken, UserNotifier, Invite, TempUser}
  alias Rannect.Rannections.Chat

  ## Database getters

  @doc """
  Gets a user by email.
  
  ## Examples
  
      iex> get_user_by_email("foo@example.com")
      %User{}
  
      iex> get_user_by_email("unknown@example.com")
      nil
  
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  
  ## Examples
  
      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}
  
      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil
  
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)

    cond do
      !User.valid_password?(user, password) -> {:error, :bad_username_or_password}
      !User.is_confirmed?(user) -> {:error, :not_confirmed}
      true -> {:ok, user}
    end
  end

  @doc """
  Gets a single user.
  
  Raises `Ecto.NoResultsError` if the User does not exist.
  
  ## Examples
  
      iex> get_user!(123)
      %User{}
  
      iex> get_user!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single temp user.
  
  Raises `Ecto.NoResultsError` if the TempUser does not exist.
  
  ## Examples
  
      iex> get_temp_user!(123)
      %TempUser{}
  
      iex> get_temp_user!(456)
      ** (Ecto.NoResultsError)
  """
  def get_temp_user!(id), do: Repo.get!(TempUser, id)

  ## User registration

  @doc """
  Registers a user.
  
  ## Examples
  
      iex> register_user(%{field: value})
      {:ok, %User{}}
  
      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def check_and_add_username(attrs) do
    if !Map.has_key?(attrs, :username) == true do
      if Map.has_key?(attrs, :email) == true do
        newUsername =
          "#{Enum.at(String.split(Map.fetch!(attrs, :email), "@"), 0)}##{System.unique_integer()}"

        Map.merge(attrs, %{
          :username => newUsername
        })
      else
        Map.merge(attrs, %{
          :username => "undefinedUser#{System.unique_integer()}"
        })
      end
    else
      attrs
    end
  end

  def check_and_add_age(attrs) do
    if !Map.has_key?(attrs, :age) do
      Map.merge(attrs, %{
        :age => 18
      })
    else
      attrs
    end
  end

  def register_user(attrs) do
    attrs_with_username = check_and_add_username(attrs)
    attrs_with_age = check_and_add_age(attrs_with_username)

    %User{}
    |> User.registration_changeset(attrs_with_age)
    |> Repo.insert()
  end

  def register_temporary_user(attrs) do
    %TempUser{}
    |> TempUser.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  
  ## Examples
  
      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}
  
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.
  
  ## Examples
  
      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}
  
  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.
  
  ## Examples
  
      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}
  
      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}
  
  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.
  
  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.
  
  ## Examples
  
      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}
  
  """
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.
  
  ## Examples
  
      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}
  
  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.
  
  ## Examples
  
      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}
  
      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Delete all data of temporary users.
  """
  def delete_temporary_users(user_id) do
    Repo.delete_all(from TempUser, where: [id: ^user_id])
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.
  
  ## Examples
  
      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}
  
      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}
  
  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.
  
  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.
  
  ## Examples
  
      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}
  
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.
  
  ## Examples
  
      iex> get_user_by_reset_password_token("validtoken")
      %User{}
  
      iex> get_user_by_reset_password_token("invalidtoken")
      nil
  
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.
  
  ## Examples
  
      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}
  
      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}
  
  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Change user profile
  """
  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Update user Profile
  """
  def update_user_profile(user, attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.profile_changeset(user, attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Updates location of user.
  """
  def update_location(user, attrs \\ %{}) do
    user
    |> User.location_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update location of temporary user.
  """
  def update_temp_location(user, attrs \\ %{}) do
    user
    |> TempUser.location_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Get invite from id.
  
  ## Examples
  
      iex> get_invite!(1)
      %Invite{}
  
      iex> get_invite!(2)
      nil
  """
  def get_invite!(id), do: Repo.get!(Invite, id)

  @doc """
  Get temp invite from id.
  
  ## Examples
  
      iex> get_temp_invite!(1)
      %Invite{}
  
      iex> get_temp_invite!(2)
      nil
  """
  def get_temp_invite!(id), do: Repo.get!(Invite, id)

  @doc """
  Gets all invites of user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_user_sent_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_user_sent_invites(user) do
    sent_invites = Repo.all(Ecto.assoc(user, :sent_invites))
    # IO.puts("SENT INVITES: ")
    # IO.inspect(sent_invites)

    sent_invites_users =
      for invite <- sent_invites, !Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        Integer.to_string(invite[:user_user_receiver])
      end

    sent_invites_users
  end

  @doc """
  Gets all invites of user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_user_received_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_user_received_invites(user) do
    received_invites = Repo.all(Ecto.assoc(user, :received_invites))

    received_invites_users =
      for invite <- received_invites, !Invite.is_invitation_accepted?(invite), into: %{} do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite[:user_user_sender]), Integer.to_string(invite[:id])}
      end

    received_invites_users
  end

  @doc """
  Gets all invites of user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_user_sent_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_user_sent_temp_invites(user) do
    sent_temp_invites = Repo.all(Ecto.assoc(user, :sent_temp_invites))

    sent_temp_invites_users =
      for invite <- sent_temp_invites, !Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        Integer.to_string(invite[:user_temp_receiver])
      end

    sent_temp_invites_users
  end

  @doc """
  Gets all invites of user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_user_received_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_user_received_temp_invites(user) do
    received_temp_invites = Repo.all(Ecto.assoc(user, :received_temp_invites))

    received_temp_invites_users =
      for invite <- received_temp_invites,
          !Invite.is_invitation_accepted?(invite),
          into: %{} do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite[:temp_user_sender]), Integer.to_string(invite[:id])}
      end

    received_temp_invites_users
  end

  @doc """
  Gets all invites of temp user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_temp_user_sent_temp_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_temp_user_sent_invites(user) do
    sent_temp_invites = Repo.all(Ecto.assoc(user, :sent_invites))
    # IO.inspect(sent_temp_invites)

    sent_temp_invites_users =
      for invite <- sent_temp_invites, !Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        Integer.to_string(invite[:temp_user_receiver])
      end

    sent_temp_invites_users
  end

  @doc """
  Gets all invites of temp user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_temp_user_received_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_temp_user_received_invites(user) do
    received_temp_invites = Repo.all(Ecto.assoc(user, :received_invites))

    received_invites_users =
      for invite <- received_temp_invites,
          !Invite.is_invitation_accepted?(invite),
          into: %{} do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite[:user_temp_sender]), Integer.to_string(invite[:id])}
      end

    received_invites_users
  end

  @doc """
  Gets all invites of temp user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_temp_user_sent_temp_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_temp_user_sent_temp_invites(user) do
    sent_temp_invites = Repo.all(Ecto.assoc(user, :sent_temp_invites))
    # IO.inspect(sent_temp_invites)

    sent_temp_invites_users =
      for invite <- sent_temp_invites, !Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        Integer.to_string(invite[:temp_temp_receiver])
      end

    sent_temp_invites_users
  end

  @doc """
  Gets all invites of temp user.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_temp_user_received_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_temp_user_received_temp_invites(user) do
    received_temp_invites = Repo.all(Ecto.assoc(user, :received_temp_invites))

    received_invites_users =
      for invite <- received_temp_invites,
          !Invite.is_invitation_accepted?(invite),
          into: %{} do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite[:temp_temp_sender]), Integer.to_string(invite[:id])}
      end

    received_invites_users
  end

  @doc """
  Get user accepted invites.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_user_accepted_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_user_accepted_invites(user) do
    # Get all invites where inviteid = userid or invitee = userid
    # and where invitation is accepted
    all_sent_invites_of_user = Repo.all(Ecto.assoc(user, :sent_invites))
    all_received_invites_of_user = Repo.all(Ecto.assoc(user, :received_invites))

    all_sent_temp_invites_of_user = Repo.all(Ecto.assoc(user, :sent_temp_invites))
    all_received_temp_invites_of_user = Repo.all(Ecto.assoc(user, :received_temp_invites))

    # IO.inspect(all_invites)
    # IO.inspect(all_temp_invites)

    accepted_sent_invites_users =
      for invite <- all_sent_invites_of_user, Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.user_user_receiver), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    accepted_sent_temp_invites_users =
      for invite <- all_sent_temp_invites_of_user, Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.user_temp_receiver), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    accepted_received_invites_users =
      for invite <- all_received_invites_of_user, Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.user_user_sender), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    accepted_received_temp_invites_users =
      for invite <- all_received_temp_invites_of_user,
          Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.temp_user_sender), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    # IO.inspect(accepted_invites_users)
    # IO.inspect(accepted_temp_invites_users)

    Map.merge(
      accepted_sent_invites_users,
      Map.merge(
        accepted_sent_temp_invites_users,
        Map.merge(accepted_received_invites_users, accepted_received_temp_invites_users)
      )
    )
  end

  @doc """
  Get temp user accepted invites.
  
  Returns list of Invite schema.
  
  ## Examples
  
      iex> get_temp_user_accepted_invites(user)
      [%Invite{}, %Invite{}, ...]
  
  """
  def get_temp_user_accepted_invites(user) do
    # Get all invites where inviteid = userid or invitee = userid
    # and where invitation is accepted
    all_sent_invites_of_user = Repo.all(Ecto.assoc(user, :sent_invites))
    all_received_invites_of_user = Repo.all(Ecto.assoc(user, :received_invites))

    all_sent_temp_invites_of_user = Repo.all(Ecto.assoc(user, :sent_temp_invites))
    all_received_temp_invites_of_user = Repo.all(Ecto.assoc(user, :received_temp_invites))

    # IO.inspect(all_invites)
    # IO.inspect(all_temp_invites)

    accepted_sent_invites_users =
      for invite <- all_sent_invites_of_user, Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.temp_user_receiver), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    accepted_sent_temp_invites_users =
      for invite <- all_sent_temp_invites_of_user, Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.temp_temp_receiver), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    accepted_received_invites_users =
      for invite <- all_received_invites_of_user, Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.user_temp_sender), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    accepted_received_temp_invites_users =
      for invite <- all_received_temp_invites_of_user,
          Invite.is_invitation_accepted?(invite) do
        invite = Map.from_struct(invite)
        {Integer.to_string(invite.temp_temp_sender), Integer.to_string(invite.id)}
      end
      |> Enum.into(%{})

    # IO.inspect(accepted_invites_users)
    # IO.inspect(accepted_temp_invites_users)

    Map.merge(
      accepted_sent_invites_users,
      Map.merge(
        accepted_sent_temp_invites_users,
        Map.merge(accepted_received_invites_users, accepted_received_temp_invites_users)
      )
    )
  end

  defp check_temp_temp_invites_received(inviter_id, invitee_id) do
    with %Invite{} = invite <-
           Repo.get_by(Invite, temp_temp_receiver: invitee_id, temp_temp_sender: inviter_id),
         invite do
      {:error, :already_invited}
    else
      :error ->
        IO.puts("deleting invites")
        Repo.delete_all(Invite, temp_temp_sender: inviter_id, temp_temp_receiver: invitee_id)
        {:ok, :ok}

      _ ->
        {:ok, :ok}
    end
  end

  defp check_temp_user_invites_received(inviter_id, invitee_id) do
    with %Invite{} = invite <-
           Repo.get_by(Invite, temp_user_receiver: invitee_id, temp_user_sender: inviter_id),
         invite do
      {:error, :already_invited}
    else
      :error ->
        IO.puts("deleting invites")
        Repo.delete_all(Invite, temp_user_sender: inviter_id, temp_user_receiver: invitee_id)
        {:ok, :ok}

      _ ->
        {:ok, :ok}
    end
  end

  defp check_user_temp_invites_received(inviter_id, invitee_id) do
    with %Invite{} = invite <-
           Repo.get_by(Invite, user_temp_receiver: invitee_id, user_temp_sender: inviter_id),
         invite do
      {:error, :already_invited}
    else
      :error ->
        IO.puts("deleting invites")
        Repo.delete_all(Invite, user_temp_sender: inviter_id, user_temp_receiver: invitee_id)
        {:ok, :ok}

      _ ->
        {:ok, :ok}
    end
  end

  defp check_user_user_invites_received(inviter_id, invitee_id) do
    with %Invite{} = invite <-
           Repo.get_by(Invite, user_user_receiver: invitee_id, user_user_sender: inviter_id),
         invite do
      {:error, :already_invited}
    else
      :error ->
        IO.puts("deleting invites")
        Repo.delete_all(Invite, user_user_sender: inviter_id, user_user_receiver: invitee_id)
        {:ok, :ok}

      _ ->
        {:ok, :ok}
    end
  end

  @doc """
  Temp User Invite temp user.
  
  ## Examples
  
      iex> temp_invite_temp_user(attrs)
      [%User{}, %User{}, ...]
  
  """
  def temp_invite_temp_user(attrs) do
    # now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    invitee = get_temp_user!(attrs[:temp_temp_receiver])
    inviter = get_temp_user!(attrs[:temp_temp_sender])
    invitee = invitee |> Repo.preload(:received_temp_invites)
    inviter = inviter |> Repo.preload(:sent_temp_invites)

    # CHECK IF ALREADY INVITED
    case check_temp_temp_invites_received(inviter.id, invitee.id) do
      {:ok, _} ->
        case check_temp_temp_invites_received(invitee.id, inviter.id) do
          {:ok, _} ->
            case %Invite{
                   accepted: false
                 }
                 |> Invite.invite_changeset(:temp_temp, attrs)
                 |> Repo.insert() do
              {:ok, invite} ->
                invitee
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:received_temp_invites, [
                  invite | invitee.received_temp_invites
                ])

                # |> Repo.update!()

                inviter
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:sent_temp_invites, [
                  invite | inviter.sent_temp_invites
                ])

                # |> Repo.update!()
            end

            {:ok, :ok}

          {:error, :already_invited} ->
            {:error, :already_invited_user}
        end

      {:error, :already_invited} ->
        {:error, :already_invited}
    end
  end

  @doc """
  Temp User Invite user.
  
  ## Examples
  
      iex> temp_invite_user(attrs)
      [%User{}, %User{}, ...]
  
  """
  def temp_invite_user(attrs) do
    # now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    invitee = get_user!(attrs[:temp_user_receiver])
    inviter = get_temp_user!(attrs[:temp_user_sender])
    invitee = invitee |> Repo.preload(:received_temp_invites)
    inviter = inviter |> Repo.preload(:sent_invites)

    # CHECK IF ALREADY INVITED
    case check_temp_user_invites_received(inviter.id, invitee.id) do
      {:ok, _} ->
        case check_temp_user_invites_received(invitee.id, inviter.id) do
          {:ok, _} ->
            case %Invite{
                   accepted: false
                 }
                 |> Invite.invite_changeset(:temp_user, attrs)
                 |> Repo.insert() do
              {:ok, invite} ->
                invitee
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:received_temp_invites, [
                  invite | invitee.received_temp_invites
                ])

                # |> Repo.update!()

                inviter
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:sent_invites, [
                  invite | inviter.sent_temp_invites
                ])
            end

            {:ok, :ok}

          {:error, :already_invited} ->
            {:error, :already_invited_user}
        end

      {:error, :already_invited} ->
        {:error, :already_invited}
    end
  end

  @doc """
  User Invite temp user.
  
  ## Examples
  
      iex> user_invite_temp(attrs)
      [%User{}, %User{}, ...]
  
  """
  def user_invite_temp(attrs) do
    # now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    invitee = get_temp_user!(attrs[:user_temp_receiver])
    inviter = get_user!(attrs[:user_temp_sender])
    invitee = invitee |> Repo.preload(:received_invites)
    inviter = inviter |> Repo.preload(:sent_temp_invites)

    # CHECK IF ALREADY INVITED
    case check_user_temp_invites_received(inviter.id, invitee.id) do
      {:ok, _} ->
        case check_user_temp_invites_received(invitee.id, inviter.id) do
          {:ok, _} ->
            case %Invite{
                   accepted: false
                 }
                 |> Invite.invite_changeset(:user_temp, attrs)
                 |> Repo.insert() do
              {:ok, invite} ->
                invitee
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:received_invites, [
                  invite | invitee.received_temp_invites
                ])

                # |> Repo.update!()

                inviter
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:sent_temp_invites, [
                  invite | inviter.sent_temp_invites
                ])

                # |> Repo.update!()
            end

            {:ok, :ok}

          {:error, :already_invited} ->
            {:error, :already_invited}
        end

      {:error, :already_invited} ->
        {:error, :already_invited_user}
    end
  end

  @doc """
  User Invite user.
  
  ## Examples
  
      iex> user_invite_user(attrs)
      [%User{}, %User{}, ...]
  
  """
  def user_invite_user(attrs) do
    # now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    invitee = get_user!(attrs[:user_user_receiver])
    inviter = get_user!(attrs[:user_user_sender])
    invitee = invitee |> Repo.preload(:received_invites)
    inviter = inviter |> Repo.preload(:sent_invites)

    # CHECK IF ALREADY INVITED
    case check_user_user_invites_received(inviter.id, invitee.id) do
      {:ok, _} ->
        case check_user_user_invites_received(invitee.id, inviter.id) do
          {:ok, _} ->
            case %Invite{
                   accepted: false
                 }
                 |> Invite.invite_changeset(:user_user, attrs)
                 |> Repo.insert() do
              {:ok, invite} ->
                invitee
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:received_invites, [invite | invitee.received_invites])

                # |> Repo.update!()

                inviter
                |> Ecto.Changeset.change()
                |> Ecto.Changeset.put_assoc(:sent_invites, [invite | inviter.sent_invites])

                # |> Repo.update!()
            end

            {:ok, :ok}

          {:error, :already_invited} ->
            {:error, :already_invited_user}
        end

      {:error, :already_invited} ->
        {:error, :already_invited}
    end
  end

  @doc """
  Accepts invite.
  
  ## Examples
  
      iex> accept_invite(inviteid, user)
      {:ok, %User{}}
  
  """
  def accept_invite(inviteid, type, userid) do
    invite = get_invite!(inviteid)

    cond do
      Invite.is_invitation_accepted?(invite) ->
        {:error, :already_accepted}

      !Invite.is_user_invited?(invite, type, userid) ->
        {:error, :not_invited}

      true ->
        invite
        |> Ecto.Changeset.change(accepted: true)
        |> Repo.update()

        # Rannections.create_rannection(%{
        #   inviter: invite.inviter,
        #   invitee: invite.invitee
        # })
    end
  end

  @doc """
  Rejects invite.
  
  ## Examples
  
      iex> reject_invite(inviteid, user)
      {:ok, %User{}}
  
  """
  def reject_invite(inviteid, type, userid) do
    invite = get_invite!(inviteid)

    cond do
      Invite.is_invitation_accepted?(invite) -> {:error, :already_accepted}
      !Invite.is_user_invited?(invite, type, userid) -> {:error, :not_invited}
      true -> invite |> Repo.delete()
    end
  end

  @doc """
  Get Rannection User Structs
  
  ## Examples
  
      iex> get_rannections_users(rannections)
      [%User{}, %User{}, ...]
  
  """
  def get_rannections_users(rannections) do
    Map.new(rannections, fn rannection ->
      {Integer.to_string(rannection), Map.from_struct(get_user!(rannection))}
    end)
  end

  @doc """
  Adds Rannection.
  
  ## Examples
  
      iex> add_rannection(user)
      {:ok, %User{}}
  
  """
  def add_rannection(userid, rannectionid) do
    user = get_user!(userid)
    nrannections = [String.to_integer(rannectionid) | user.rannections]

    user
    |> Ecto.Changeset.change(rannections: nrannections)
    |> Repo.update()
  end

  @spec remove_rannection(any, binary) :: any
  @doc """
  Removes Rannection.
  
  ## Examples
  
      iex> remove_rannection(user)
      {:ok, %User{}}
  
  """
  def remove_rannection(userid, rannectionid) do
    user = get_user!(userid)
    nrannections = List.delete(user.rannections, String.to_integer(rannectionid))

    user
    |> Ecto.Changeset.change(rannections: nrannections)
    |> Repo.update()
  end

  @doc """
  Preloads chats for a invite.
  
  ## Examples
  
      iex> preload_invite_chats(invite)
      {:ok, %Invite{}}
  
      iex> preload_invite_chats(invite)
      {:error, %Ecto.Changeset{}}
  """
  def preload_invite_chats(%Invite{} = invite) do
    invite
    |> Repo.preload(:chats)
  end

  @doc """
  Returns the list of chats of invite.
  
  ## Examples
  
      iex> list_chats(1)
      [%Chat{}, ...]
  
  """
  def list_chats(inviteid) do
    query = from chat in Chat, where: chat.invite_id == ^inviteid
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
  Creates a temp chat.
  
  ## Examples
  
      iex> create_chat(%{field: value})
      {:ok, %Chat{}}
  
      iex> create_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_chat(invite, attrs \\ %{}) do
    invite
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
  Deletes a temp chat.
  
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
