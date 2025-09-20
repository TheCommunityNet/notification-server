defmodule ComnetWebsocket.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :key, Ecto.UUID
    field :payload, :map
    field :sent_count, :integer
    field :received_count, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:key, :payload, :sent_count, :received_count])
    |> validate_required([:key, :sent_count, :received_count])
  end
end
