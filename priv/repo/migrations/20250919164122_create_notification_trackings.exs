defmodule ComnetWebsocket.Repo.Migrations.CreateNotificationTrackings do
  use Ecto.Migration

  def change do
    create table(:notification_trackings) do
      add :notification_key, :uuid
      add :user_id, :string
      add :received_at, :utc_datetime

      timestamps(type: :utc_datetime)

      index(:notification_trackings, [:notification_key, :user_id], unique: true)
    end
  end
end
