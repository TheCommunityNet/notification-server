defmodule ComnetWebsocket.Models.Shelly do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: UUIDv7.t() | nil,
          name: String.t() | nil,
          ip_address: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "shellies" do
    field :name, :string
    field :ip_address, :string

    many_to_many :users, ComnetWebsocket.Models.User,
      join_through: "user_shellies",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shelly, attrs) do
    shelly
    |> cast(attrs, [:name, :ip_address])
    |> validate_required([:name, :ip_address])
  end

  def update_changeset(shelly, attrs) do
    shelly
    |> cast(attrs, [:name, :ip_address])
    |> validate_required([:name, :ip_address])
  end
end
