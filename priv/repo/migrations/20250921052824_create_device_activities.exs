defmodule ComnetWebsocket.Repo.Migrations.CreateDeviceActivities do
  use Ecto.Migration

  def change do
    create table(:device_activities) do
      add :device_id, :string, null: false
      add :user_id, :string
      add :connection_id, :uuid, null: false
      add :ip_address, :string
      add :started_at, :utc_datetime, null: false
      add :ended_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:device_activities, [:device_id, :connection_id], unique: true)
    create index(:device_activities, [:user_id])
  end
end
