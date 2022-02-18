defmodule Rannect.Repo.Migrations.CreateTempUsers do
  use Ecto.Migration

  def change do
    create table(:temp_users) do
      add :username, :string, required: true
      add :ip_address, :string, required: true
      add :location, :map, default: %{}
      timestamps()
    end

    create unique_index(:temp_users, [:username])
    create unique_index(:temp_users, [:ip_address])
  end
end
