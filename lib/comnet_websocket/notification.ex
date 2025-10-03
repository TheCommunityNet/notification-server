defmodule ComnetWebsocket.Notification do
  @moduledoc """
  Schema for notifications.

  Represents a notification that can be sent to users or devices.
  Notifications can have different types (user/device) and categories.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer() | nil,
          key: Ecto.UUID.t() | nil,
          group_key: String.t() | nil,
          type: String.t() | nil,
          category: String.t() | nil,
          payload: map() | nil,
          sent_count: integer() | nil,
          received_count: integer() | nil,
          expired_at: DateTime.t() | nil,
          is_expired: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "notifications" do
    field :key, Ecto.UUID
    field :group_key, :string
    field :type, :string
    field :category, :string
    field :payload, :map
    field :sent_count, :integer
    field :received_count, :integer
    field :expired_at, :utc_datetime
    field :is_expired, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a notification.

  ## Parameters
  - `notification` - The notification struct
  - `attrs` - The attributes to change

  ## Returns
  - A changeset
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :key,
      :group_key,
      :type,
      :category,
      :payload,
      :sent_count,
      :received_count,
      :expired_at,
      :is_expired
    ])
    |> validate_required([
      :key,
      :type,
      :category,
      :sent_count,
      :received_count,
      :expired_at,
      :is_expired
    ])
  end
end
