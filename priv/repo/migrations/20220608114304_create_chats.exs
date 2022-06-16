defmodule Rannect.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats) do
      add :message, :text
      add :img_url, :text
      add :sender, references(:users, on_delete: :delete_all)
      add :temp_sender, references(:temp_users, on_delete: :delete_all)
      add :invite_id, references(:invites, on_delete: :delete_all)

      timestamps()
    end

    create index(:chats, [:sender])
    create index(:chats, [:temp_sender])
    create index(:chats, [:invite_id])
  end
end
