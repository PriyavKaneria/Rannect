defmodule Rannect.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites) do
      add :accepted, :boolean, default: false, null: false
      # User -> User Invite
      add :user_user_sender, references(:users, on_delete: :delete_all)
      add :user_user_receiver, references(:users, on_delete: :delete_all)
      # User -> Temp User Invite
      add :user_temp_sender, references(:users, on_delete: :delete_all)
      add :user_temp_receiver, references(:temp_users, on_delete: :delete_all)
      # Temp User -> User Invite
      add :temp_user_sender, references(:temp_users, on_delete: :delete_all)
      add :temp_user_receiver, references(:users, on_delete: :delete_all)
      # Temp User -> Temp User Invite
      add :temp_temp_sender, references(:temp_users, on_delete: :delete_all)
      add :temp_temp_receiver, references(:temp_users, on_delete: :delete_all)

      timestamps()
    end

    create index(:invites, [:user_user_sender])
    create index(:invites, [:user_user_receiver])
    create index(:invites, [:user_temp_sender])
    create index(:invites, [:user_temp_receiver])
    create index(:invites, [:temp_user_sender])
    create index(:invites, [:temp_user_receiver])
    create index(:invites, [:temp_temp_sender])
    create index(:invites, [:temp_temp_receiver])
  end
end
