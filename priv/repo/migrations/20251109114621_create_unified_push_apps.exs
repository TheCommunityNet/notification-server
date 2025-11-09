defmodule ComnetWebsocket.Repo.Migrations.CreateUnifiedPushApps do
  use Ecto.Migration

  def change do
    create table(:unified_push_apps) do
      add :app_id, :string
      add :connector_token, :string
      add :device_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:unified_push_apps, [:app_id, :connector_token], unique: true)
    create index(:unified_push_apps, [:device_id])
  end
end
