defmodule ComnetWebsocketWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting requests.

  This plug limits the number of requests per identifier (e.g., device_id)
  within a specified time window using ETS (Erlang Term Storage).
  """

  import Plug.Conn
  import Phoenix.Controller
  require Logger

  @table_name :rate_limit_table
  @default_max_requests 10
  @default_window_seconds 60

  @doc """
  Initializes the plug.

  ## Parameters
  - `opts` - Options map with:
    - `:max_requests` - Maximum number of requests (default: 10)
    - `:window_seconds` - Time window in seconds (default: 60)
    - `:key_func` - Function to extract the key from the connection (default: extracts device_id from path params)

  ## Returns
  - The options
  """
  @spec init(keyword()) :: keyword()
  def init(opts) do
    max_requests = Keyword.get(opts, :max_requests, @default_max_requests)
    window_seconds = Keyword.get(opts, :window_seconds, @default_window_seconds)
    key_func = Keyword.get(opts, :key_func, &default_key_func/1)

    ensure_table_exists()

    [
      max_requests: max_requests,
      window_seconds: window_seconds,
      key_func: key_func
    ]
  end

  @doc """
  Checks if the request is within the rate limit.

  ## Parameters
  - `conn` - The connection
  - `opts` - Plug options

  ## Returns
  - The connection (possibly halted with 429 status)
  """
  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, opts) do
    key_func = Keyword.fetch!(opts, :key_func)
    max_requests = Keyword.fetch!(opts, :max_requests)
    window_seconds = Keyword.fetch!(opts, :window_seconds)

    case key_func.(conn) do
      nil ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Missing identifier for rate limiting"})
        |> halt()

      key ->
        if check_rate_limit(key, max_requests, window_seconds) do
          conn
        else
          conn
          |> put_status(:too_many_requests)
          |> json(%{
            error: "Rate limit exceeded. Maximum #{max_requests} requests per #{window_seconds} seconds."
          })
          |> halt()
        end
    end
  end

  # Default key function: extracts device_id from path params
  defp default_key_func(conn) do
    Map.get(conn.path_params, "device_id")
  end

  # Ensure the ETS table exists
  defp ensure_table_exists do
    case :ets.whereis(@table_name) do
      :undefined ->
        :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])

      _pid ->
        :ok
    end
  end

  # Check if the request is within rate limit
  defp check_rate_limit(key, max_requests, window_seconds) do
    now = System.system_time(:second)
    window_start = now - window_seconds

    # Get or create entry for this key
    case :ets.lookup(@table_name, key) do
      [] ->
        # First request for this key
        :ets.insert(@table_name, {key, {now, 1}})
        true

      [{_key, {window_start_time, count}}] ->
        if window_start_time > window_start do
          # Still within the current window
          if count < max_requests do
            new_count = count + 1
            :ets.insert(@table_name, {key, {window_start_time, new_count}})
            true
          else
            false
          end
        else
          # Window expired, reset
          :ets.insert(@table_name, {key, {now, 1}})
          true
        end
    end
  end

  @doc """
  Clears rate limit data for a specific key (useful for testing).
  """
  @spec clear_key(String.t()) :: :ok
  def clear_key(key) do
    ensure_table_exists()
    :ets.delete(@table_name, key)
    :ok
  end

  @doc """
  Clears all rate limit data (useful for testing).
  """
  @spec clear_all() :: :ok
  def clear_all do
    ensure_table_exists()
    :ets.delete_all_objects(@table_name)
    :ok
  end
end
