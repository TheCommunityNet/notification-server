defmodule ComnetWebsocketWeb.Plugs.ApiKeyAuth do
  import Plug.Conn

  @api_key Application.compile_env(:comnet_websocket, :api_key)

  def init(default), do: default

  def call(conn, _opts) do
    case get_req_header(conn, "x-api-key") do
      [key] ->
        if @api_key != nil and key == @api_key do
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
