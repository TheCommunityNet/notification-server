defmodule ComnetWebsocketWeb.Plugs.UserAccessTokenAuth do
  @moduledoc """
  Plug that authenticates requests using a Bearer access token in the
  Authorization header.

  On success, assigns `:current_user` to the connection.
  On failure, halts with 401.
  """

  import Plug.Conn

  alias ComnetWebsocket.Services.UserService

  @spec init(any()) :: any()
  def init(default), do: default

  @spec call(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def call(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         user when not is_nil(user) <- UserService.get_user_by_access_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()
    end
  end
end
