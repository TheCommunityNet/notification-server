defmodule ComnetWebsocket.NotificationTracking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notification_trackings" do
    field :notification_key, Ecto.UUID
    field :user_id, :string
    field :received_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification_tracking, attrs) do
    notification_tracking
    |> cast(attrs, [:notification_key, :user_id, :received_at])
    |> validate_required([:notification_key, :user_id, :received_at])
  end
end
