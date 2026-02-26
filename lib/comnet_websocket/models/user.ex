defmodule ComnetWebsocket.Models.User do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: UUIDv7.t() | nil,
          name: String.t() | nil,
          device_id: String.t() | nil,
          otp_token: String.t() | nil,
          access_token: String.t() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "users" do
    field :name, :string
    field :device_id, :string
    field :otp_token, :string
    field :access_token, :string

    many_to_many :shellies, ComnetWebsocket.Models.Shelly,
      join_through: "user_shellies",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :device_id, :otp_token, :access_token])
    |> validate_required([:name, :device_id, :otp_token, :access_token])
  end

  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def admin_create_changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> put_change(:access_token, generate_access_token())
  end

  def verify_otp_changeset(user, device_id) do
    Ecto.Changeset.change(user, device_id: device_id, otp_token: nil)
  end

  def generate_otp_changeset(user) do
    Ecto.Changeset.change(user, otp_token: generate_otp_token())
  end

  def regenerate_access_token_changeset(user) do
    Ecto.Changeset.change(user, access_token: generate_access_token())
  end

  defp generate_otp_token do
    :crypto.strong_rand_bytes(3) |> Base.encode16()
  end

  defp generate_access_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end
end
