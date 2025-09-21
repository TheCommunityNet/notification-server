defmodule ComnetWebsocket.Repo.Migrations.CreateNotificationTrackings do
  use Ecto.Migration

  def change do
    create table(:notification_trackings) do
      add :notification_key, :uuid, null: false
      add :user_id, :string
      add :device_id, :string
      add :received_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:notification_trackings, [:notification_key])
    create index(:notification_trackings, [:user_id])
    create index(:notification_trackings, [:device_id])
  end
end
