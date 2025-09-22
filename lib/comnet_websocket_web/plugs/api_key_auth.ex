defmodule ComnetWebsocketWeb.Plugs.ApiKeyAuth do
  @moduledoc """
  Plug for API key authentication.

  This plug validates API keys sent in the x-api-key header
  for protected endpoints.
  """

  import Plug.Conn
  alias ComnetWebsocket.Constants

  @doc """
  Initializes the plug.

  ## Parameters
  - `default` - Default options

  ## Returns
  - The options
  """
  @spec init(any()) :: any()
  def init(default), do: default

  @doc """
  Validates the API key from the request header.

  ## Parameters
  - `conn` - The connection
  - `_opts` - Plug options (unused)

  ## Returns
  - The connection (possibly halted)
  """
  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _opts) do
    api_key = Application.get_env(:comnet_websocket, :api_key)

    case get_req_header(conn, "x-api-key") do
      [key] ->
        if api_key != nil and key == api_key do
          conn
        else
          conn
          |> send_resp(401, Constants.api_message_unauthorized())
          |> halt()
        end

      _ ->
        conn
        |> send_resp(401, Constants.api_message_unauthorized())
        |> halt()
    end
  end
end
