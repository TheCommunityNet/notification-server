defmodule ComnetWebsocket.Repo.Migrations.CreateShellyAlerts do
  use Ecto.Migration

  def change do
    create table(:shelly_alerts) do
      add :shelly_id, references(:shellies, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:shelly_alerts, [:shelly_id])
    create index(:shelly_alerts, [:user_id])
  end
end
