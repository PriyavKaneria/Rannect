defmodule Rannect.Repo.Migrations.CreateTempInvites do
  use Ecto.Migration

  def change do
    create table(:temp_invites) do
      add :accepted, :boolean, default: false, null: false
      add :inviter, references(:temp_users, on_delete: :delete_all)
      add :invitee, references(:temp_users, on_delete: :delete_all)

      timestamps()
    end

    create index(:temp_invites, [:inviter])
    create index(:temp_invites, [:invitee])
  end
end
