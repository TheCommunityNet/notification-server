defmodule ComnetWebsocket.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :device_id, :string
      add :otp_token, :string
      add :access_token, :string

      timestamps(type: :utc_datetime)
    end
  end
end
