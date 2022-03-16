# defmodule Rannect.Rannections.Rannection do
#   use Ecto.Schema
#   import Ecto.Changeset

#   alias Rannect.Users.User

#   schema "rannections" do
#     field :blocked, :boolean, default: false
#     belongs_to :inviter_id, User, foreign_key: :inviter
#     belongs_to :invitee_id, User, foreign_key: :invitee

#     timestamps()
#   end

#   @doc false
#   def changeset(rannection, attrs) do
#     rannection
#     |> cast(attrs, [:blocked, :inviter, :invitee])
#     |> validate_required([:blocked, :inviter, :invitee])
#   end
# end
