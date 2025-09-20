defmodule ComnetWebsocket.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications) do
      add :key, :uuid
      add :payload, :map
      add :sent_count, :integer
      add :received_count, :integer

      timestamps(type: :utc_datetime)

      index(:notifications, [:key], unique: true)
    end
  end
end
