defmodule ComnetWebsocket.Repo.Migrations.AddIpAddressToDeviceActivitiesTable do
  use Ecto.Migration

  def change do
    alter table(:device_activities) do
      add :ip_address, :string
    end
  end
end
