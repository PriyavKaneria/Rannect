defmodule Rannect.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats) do
      add :message, :text
      add :img_url, :text
      add :sender, references(:users, on_delete: :delete_all)
      add :rannection_id, references(:rannections, on_delete: :delete_all)

      timestamps()
    end

    create index(:chats, [:sender])
    create index(:chats, [:rannection_id])
  end
end
