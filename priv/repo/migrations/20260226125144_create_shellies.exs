defmodule ComnetWebsocket.Repo.Migrations.CreateShellies do
  use Ecto.Migration

  def change do
    create table(:shellies) do
      add :name, :string
      add :ip_address, :string

      timestamps(type: :utc_datetime)
    end
  end
end
