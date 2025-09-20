defmodule ComnetWebsocket.Repo do
  use Ecto.Repo,
    otp_app: :comnet_websocket,
    adapter: Ecto.Adapters.Postgres
end
