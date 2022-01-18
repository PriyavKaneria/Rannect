defmodule Rannect.Users.Invite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.User

  schema "invites" do
    field :accepted, :boolean, default: false
    belongs_to :inviter_id, User, foreign_key: :inviter
    belongs_to :invitee_id, User, foreign_key: :invitee

    timestamps()
  end

  @doc false
  def invite_changeset(invite, attrs) do
    invite
    |> cast(attrs, [:inviter, :invitee, :accepted])
    |> foreign_key_constraint(:invitee)
    |> foreign_key_constraint(:inviter)
    |> assoc_constraint(:invitee_id)
    |> assoc_constraint(:inviter_id)
    |> validate_required([:inviter, :invitee, :accepted])
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
