defmodule Rannect.Rannections.Chat do
  use Ecto.Schema
  import Ecto.Changeset

  alias Rannect.Rannections.Rannection

  schema "chats" do
    field :img_url, :string
    field :message, :string
    field :sender, :id
    belongs_to :rannection, Rannection

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:message, :img_url, :sender])
    |> validate_required([:message])
  end
end
