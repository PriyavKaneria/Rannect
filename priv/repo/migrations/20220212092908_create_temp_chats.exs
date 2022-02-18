defmodule Rannect.Repo.Migrations.CreateTempChats do
  use Ecto.Migration

  def change do
    create table(:temp_chats) do
      add :message, :text
      add :img_url, :text
      add :sender, references(:users, on_delete: :delete_all)
      add :temp_sender, references(:temp_users, on_delete: :delete_all)
      add :temp_invite_id, references(:temp_invites, on_delete: :delete_all)

      timestamps()
    end

    create index(:temp_chats, [:sender])
    create index(:temp_chats, [:temp_sender])
    create index(:temp_chats, [:temp_invite_id])
  end
end
