defmodule Rannect.Rannections.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Users.Invite

  schema "chats" do
    field :message, :string
    field :img_url, :string
    field :sender, :id
    field :temp_sender, :id
    belongs_to :invite, Invite

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:message, :img_url, :sender, :temp_sender])
    |> validate_required([:message])
  end
end
