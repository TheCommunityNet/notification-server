defmodule ComnetWebsocket.Repo.Migrations.CreateUserShellies do
  use Ecto.Migration

  def change do
    create table(:user_shellies, primary_key: false) do
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :shelly_id, references(:shellies, type: :uuid, on_delete: :delete_all), null: false
    end

    create unique_index(:user_shellies, [:user_id, :shelly_id])
    create index(:user_shellies, [:shelly_id])
  end
end
