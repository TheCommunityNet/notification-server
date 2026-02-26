defmodule ComnetWebsocketWeb.ShellyController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.AlertService

  plug ComnetWebsocketWeb.Plugs.UserAccessTokenAuth

  @doc """
  Lists all shellies assigned to the authenticated user.
  Returns only `id` and `name` for each shelly.
  """
  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, _params) do
    shellies = AlertService.list_user_shellies(conn.assigns.current_user)
    json(conn, %{data: shellies})
  end
end
