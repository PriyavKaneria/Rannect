defmodule Rannect.Repo.Migrations.CreateTempInvites do
  use Ecto.Migration

  def change do
    create table(:temp_invites) do
      add :accepted, :boolean, default: false, null: false
      add :temp_inviter, references(:temp_users, on_delete: :delete_all)
      add :temp_invitee, references(:temp_users, on_delete: :delete_all)
      add :inviter, references(:users, on_delete: :delete_all)
      add :invitee, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:temp_invites, [:inviter])
    create index(:temp_invites, [:invitee])
    create index(:temp_invites, [:temp_inviter])
    create index(:temp_invites, [:temp_invitee])
  end
end
