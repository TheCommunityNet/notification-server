defmodule ComnetWebsocket.ULIDType do
  @moduledoc """
  Ecto type for ULID (Universally Unique Lexicographically Sortable Identifier).

  ULIDs are 128-bit identifiers that are:
  - Lexicographically sortable
  - URL-safe
  - 26 characters when encoded as base32
  - More compact than UUIDs
  - Time-ordered (first 48 bits are timestamp)
  """

  use Ecto.Type

  @impl true
  def type, do: :binary

  @impl true
  def cast(value) when is_binary(value) do
    # Handle binary ULID data (16 bytes)
    case byte_size(value) do
      16 -> {:ok, value}
      _ -> :error
    end
  end

  def cast(_), do: :error

  @impl true
  def load(value) when is_binary(value) do
    case byte_size(value) do
      16 -> {:ok, value}
      _ -> :error
    end
  end

  @impl true
  def dump(value) when is_binary(value) do
    case byte_size(value) do
      16 -> {:ok, value}
      _ -> :error
    end
  end

  def dump(_), do: :error

  @impl true
  def autogenerate do
    Ulid.generate_binary()
  end

  @doc """
  Generate a new ULID as binary.
  """
  def generate do
    Ulid.generate_binary()
  end

  @doc """
  Generate a new ULID as binary with a specific timestamp.
  """
  def generate(timestamp) do
    Ulid.generate_binary(timestamp)
  end
end
