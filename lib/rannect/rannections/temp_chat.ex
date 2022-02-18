defmodule Rannect.Rannections.TempChat do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.TempInvite

  schema "temp_chats" do
    field :message, :string
    field :img_url, :string
    field :sender, :id
    field :temp_sender, :id
    belongs_to :temp_invites, TempInvite

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:message, :img_url, :sender])
    |> validate_required([:message])
  end
end
