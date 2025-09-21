defmodule ComnetWebsocketWeb.Plugs.ApiKeyAuth do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _opts) do
    api_key = Application.get_env(:comnet_websocket, :api_key)

    case get_req_header(conn, "x-api-key") do
      [key] ->
        if api_key != nil and key == api_key do
          conn
        else
          conn
          |> send_resp(401, "Unauthorized")
          |> halt()
        end

      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end
end
