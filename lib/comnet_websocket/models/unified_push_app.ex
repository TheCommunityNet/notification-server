defmodule ComnetWebsocket.Models.UnifiedPushApp do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: UUIDv7.t() | nil,
          app_id: String.t() | nil,
          connector_token: String.t() | nil,
          device_id: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "unified_push_apps" do
    field :app_id, :string
    field :connector_token, :string
    field :device_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(unified_push_app, attrs) do
    unified_push_app
    |> cast(attrs, [:app_id, :connector_token, :device_id])
    |> validate_required([:app_id, :connector_token, :device_id])
    |> unique_constraint(:app_id, name: :unified_push_apps_app_id_connector_token_index)
    |> unique_constraint(:device_id, name: :unified_push_apps_device_id_index)
  end
end
