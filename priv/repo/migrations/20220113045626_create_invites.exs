defmodule Rannect.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add :accepted, :boolean, default: false, null: false
      add :invited_on, :naive_datetime
      add :inviter, references(:users, on_delete: :delete_all)
      add :invitee, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:invites, [:inviter])
    create index(:invites, [:invitee])
  end
end
