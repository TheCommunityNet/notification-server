defmodule ComnetWebsocket.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :device_id, :string
      add :otp_token, :string
      add :access_token, :string
      add :is_banned, :boolean, default: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:otp_token])
  end
end
