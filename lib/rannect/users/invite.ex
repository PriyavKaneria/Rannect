defmodule Rannect.Users.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.{User, TempUser}
  alias Rannect.Rannections.{Chat}

  schema "invites" do
    field :accepted, :boolean, default: false

    belongs_to :user_user_sender_id, User, foreign_key: :user_user_sender
    belongs_to :user_user_receiver_id, User, foreign_key: :user_user_receiver
    belongs_to :user_temp_sender_id, User, foreign_key: :user_temp_sender
    belongs_to :user_temp_receiver_id, TempUser, foreign_key: :user_temp_receiver
    belongs_to :temp_user_sender_id, TempUser, foreign_key: :temp_user_sender
    belongs_to :temp_user_receiver_id, User, foreign_key: :temp_user_receiver
    belongs_to :temp_temp_sender_id, TempUser, foreign_key: :temp_temp_sender
    belongs_to :temp_temp_receiver_id, TempUser, foreign_key: :temp_temp_receiver

    has_many :chats, Chat

    timestamps()
  end

  @doc """
  Returns invite changeset properly cast, contrained and associated
  """
  def invite_changeset(invite, type, attrs) do
    case type do
      :user_user ->
        invite
        |> cast(attrs, [:user_user_sender, :user_user_receiver, :accepted])
        |> foreign_key_constraint(:user_user_receiver)
        |> foreign_key_constraint(:user_user_sender)
        |> assoc_constraint(:user_user_receiver_id)
        |> assoc_constraint(:user_user_sender_id)
        |> validate_required([:user_user_sender, :user_user_receiver, :accepted])

      :temp_temp ->
        invite
        |> cast(attrs, [:temp_temp_sender, :temp_temp_receiver, :accepted])
        |> foreign_key_constraint(:temp_temp_receiver)
        |> foreign_key_constraint(:temp_temp_sender)
        |> assoc_constraint(:temp_temp_receiver_id)
        |> assoc_constraint(:temp_temp_sender_id)
        |> validate_required([:temp_temp_sender, :temp_temp_receiver, :accepted])

      :user_temp ->
        invite
        |> cast(attrs, [:user_temp_sender, :user_temp_receiver, :accepted])
        |> foreign_key_constraint(:user_temp_receiver)
        |> foreign_key_constraint(:user_temp_sender)
        |> assoc_constraint(:user_temp_receiver_id)
        |> assoc_constraint(:user_temp_sender_id)
        |> validate_required([:user_temp_sender, :user_temp_receiver, :accepted])

      :temp_user ->
        invite
        |> cast(attrs, [:temp_user_sender, :temp_user_receiver, :accepted])
        |> foreign_key_constraint(:temp_user_receiver)
        |> foreign_key_constraint(:temp_user_sender)
        |> assoc_constraint(:temp_user_receiver_id)
        |> assoc_constraint(:temp_user_sender_id)
        |> validate_required([:temp_user_sender, :temp_user_receiver, :accepted])

      _ ->
        raise "Invalid invite type: #{type}"
    end
  end

  @doc """
  Returns true if the invite is accepted by invitee, false otherwise
  """
  def is_invitation_accepted?(invite), do: invite.accepted == true

  @doc """
  Returns true if the user is invited in the invite, false otherwise
  """
  def is_user_invited?(invite, type, userid) do
    case type do
      :user_user ->
        invite.user_user_receiver == userid

      :temp_temp ->
        invite.temp_temp_receiver == userid

      :user_temp ->
        invite.user_temp_receiver == userid

      :temp_user ->
        invite.temp_user_receiver == userid

      _ ->
        raise "Invalid invite type: #{type}"
    end
  end
end
