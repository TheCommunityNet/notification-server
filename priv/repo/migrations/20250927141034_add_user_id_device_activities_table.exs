defmodule ComnetWebsocket.Repo.Migrations.AddUserIdDeviceActivitiesTable do
  use Ecto.Migration

  def change do
    alter table(:device_activities) do
      add :user_id, :string
    end

    create index(:device_activities, [:user_id])
  end
end
