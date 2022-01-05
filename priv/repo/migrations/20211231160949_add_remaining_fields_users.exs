defmodule Rannect.Repo.Migrations.AddRemainingFieldsUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add_if_not_exists(:username, :string, required: true)
      add_if_not_exists(:gender, :string, default: "male")
      add_if_not_exists(:age, :integer)
      add_if_not_exists(:location, :map, default: %{})
      add_if_not_exists(:online, :boolean, default: false)
    end
  end
end
