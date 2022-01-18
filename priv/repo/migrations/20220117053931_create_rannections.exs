defmodule Rannect.Repo.Migrations.CreateRannections do
  use Ecto.Migration

  def change do
    create table(:rannections) do
      add :blocked, :boolean, default: false, null: false
      add :inviter, references(:users, on_delete: :delete_all)
      add :invitee, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:rannections, [:inviter])
    create index(:rannections, [:invitee])
  end
end
