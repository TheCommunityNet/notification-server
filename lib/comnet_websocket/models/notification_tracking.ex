defmodule ComnetWebsocket.Models.NotificationTracking do
  @moduledoc """
  Schema for notification tracking.

  Tracks the delivery and receipt status of notifications for specific
  users or devices.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: UUIDv7.t() | nil,
          notification_key: Ecto.UUID.t() | nil,
          user_id: String.t() | nil,
          device_id: String.t() | nil,
          received_at: DateTime.t() | nil,
          is_received: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "notification_trackings" do
    field :notification_key, Ecto.UUID
    field :user_id, :string
    field :device_id, :string
    field :received_at, :utc_datetime
    field :is_received, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for notification tracking.

  ## Parameters
  - `notification_tracking` - The notification tracking struct
  - `attrs` - The attributes to change

  ## Returns
  - A changeset
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(notification_tracking, attrs) do
    notification_tracking
    |> cast(attrs, [:notification_key, :user_id, :device_id, :received_at, :is_received])
    |> validate_required([:notification_key, :is_received])
  end
end
