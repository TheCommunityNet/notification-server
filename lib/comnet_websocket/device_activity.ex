defmodule ComnetWebsocket.DeviceActivity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "device_activities" do
    field :device_id, :string
    field :connection_id, Ecto.UUID
    field :started_at, :utc_datetime
    field :ended_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device_activity, attrs) do
    device_activity
    |> cast(attrs, [:device_id, :connection_id, :started_at, :ended_at])
    |> validate_required([:device_id, :connection_id, :started_at])
  end
end
