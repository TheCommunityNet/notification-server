defmodule ComnetWebsocket.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :key, Ecto.UUID
    field :type, :string
    field :category, :string
    field :payload, :map
    field :sent_count, :integer
    field :received_count, :integer
    field :expired_at, :utc_datetime
    field :is_expired, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [
      :key,
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
