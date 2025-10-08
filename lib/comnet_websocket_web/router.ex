defmodule ComnetWebsocketWeb.Router do
  use ComnetWebsocketWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ComnetWebsocketWeb do
    pipe_through :api

    scope "/v1" do
      post "/notification/send", NotificationController, :send_notification
      get "/connection/active", ConnectionController, :active_connections
      get "/connection/active/users", ConnectionController, :active_users
    end
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:comnet_websocket, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: ComnetWebsocketWeb.Telemetry
    end
  end

  if Mix.env() == :prod do
    import Phoenix.LiveDashboard.Router
    import Plug.BasicAuth

    defp dashboard_auth_plug(conn, _opts) do
      dashboard_auth = Application.get_env(:comnet_websocket, :dashboard_auth, [])

      Plug.BasicAuth.basic_auth(conn,
        username: dashboard_auth[:username],
        password: dashboard_auth[:password]
      )
    end

    pipeline :dashboard_auth do
      plug :dashboard_auth_plug
    end

    scope "/dashboard" do
      pipe_through [:fetch_session, :dashboard_auth]
      live_dashboard "/", metrics: ComnetWebsocketWeb.Telemetry
    end
  end
end
