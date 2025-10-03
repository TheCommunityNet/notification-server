defmodule ComnetWebsocket.Repo.Migrations.AddGroupKeyToNotificationsTable do
  use Ecto.Migration

  def change do
    alter table(:notifications) do
      add :group_key, :string
    end

    create index(:notifications, [:group_key])
  end
end
