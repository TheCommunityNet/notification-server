defmodule ComnetWebsocket.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :device_id, :string, null: false
      add :last_active_at, :utc_datetime

      timestamps(type: :utc_datetime)

      index(:devices, [:device_id], unique: true)
    end
  end
end
