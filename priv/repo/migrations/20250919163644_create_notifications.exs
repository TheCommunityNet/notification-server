defmodule ComnetWebsocket.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :key, :uuid, null: false
      add :type, :string, null: false
      add :payload, :map, null: false
      add :sent_count, :integer
      add :received_count, :integer
      add :expired_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:type])
    create index(:notifications, [:key], unique: true)
    create index(:notifications, [:expired_at])
  end
end
