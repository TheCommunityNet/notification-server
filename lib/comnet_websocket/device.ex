defmodule ComnetWebsocket.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field :device_id, :string
    field :last_active_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:device_id, :last_active_at])
    |> validate_required([:device_id, :last_active_at])
    |> unique_constraint(:device_id)
  end
end
