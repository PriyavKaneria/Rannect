defmodule Rannect.Users.TempInvite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.User
  alias Rannect.Users.TempUser
  alias Rannect.Rannections.TempChat

  schema "temp_invites" do
    field :accepted, :boolean, default: false
    belongs_to :temp_inviter_id, TempUser, foreign_key: :temp_inviter
    belongs_to :temp_invitee_id, TempUser, foreign_key: :temp_invitee
    belongs_to :inviter_id, User, foreign_key: :inviter
    belongs_to :invitee_id, User, foreign_key: :invitee

    has_many :temp_chats, TempChat

    timestamps()
  end

  @doc false
  def invite_changeset(invite, attrs) do
    invite
    |> cast(attrs, [:inviter, :invitee, :temp_inviter_id, :temp_invitee_id, :accepted])
    |> foreign_key_constraint(:invitee)
    |> foreign_key_constraint(:inviter)
    |> foreign_key_constraint(:temp_invitee)
    |> foreign_key_constraint(:temp_inviter)
    |> assoc_constraint(:invitee_id)
    |> assoc_constraint(:inviter_id)
    |> assoc_constraint(:temp_invitee_id)
    |> assoc_constraint(:temp_inviter_id)
    |> validate_required([:inviter, :invitee, :temp_inviter_id, :temp_invitee_id, :accepted])
  end

  @doc """
  Returns true if the invite is accepted by invitee, false otherwise
  """
  def is_invitation_accepted?(invite), do: invite.accepted == true

  @doc """
  Returns true if the user is invited in the invite, false otherwise
  """
  def is_user_invited?(invite, userid), do: invite.invitee == userid
end
