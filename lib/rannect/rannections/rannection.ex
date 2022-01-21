defmodule Rannect.Rannections.Rannection do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.User
  alias Rannect.Rannections.Chat

  schema "rannections" do
    field :blocked, :boolean, default: false
    belongs_to :inviter_id, User, foreign_key: :inviter
    belongs_to :invitee_id, User, foreign_key: :invitee

    has_many :chats, Chat

    timestamps()
  end

  @doc false
  def changeset(rannection, attrs) do
    rannection
    |> cast(attrs, [:blocked, :inviter, :invitee])
    |> validate_required([:blocked, :inviter, :invitee])
  end
end
