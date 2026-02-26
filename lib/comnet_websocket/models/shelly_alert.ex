defmodule ComnetWebsocket.Models.ShellyAlert do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: UUIDv7.t() | nil,
          shelly_id: UUIDv7.t() | nil,
          user_id: UUIDv7.t() | nil,
          inserted_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "shelly_alerts" do
    belongs_to :shelly, ComnetWebsocket.Models.Shelly, type: UUIDv7
    belongs_to :user, ComnetWebsocket.Models.User, type: UUIDv7

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(alert, attrs) do
    alert
    |> cast(attrs, [:shelly_id, :user_id])
    |> validate_required([:shelly_id, :user_id])
    |> assoc_constraint(:shelly)
    |> assoc_constraint(:user)
  end
end
