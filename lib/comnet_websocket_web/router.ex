defmodule ComnetWebsocketWeb.Router do
  use ComnetWebsocketWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ComnetWebsocketWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_auth do
    plug :admin_basic_auth
  end

  defp admin_basic_auth(conn, _opts) do
    creds = Application.get_env(:comnet_websocket, :admin_auth, [])

    Plug.BasicAuth.basic_auth(conn,
      username: creds[:username] || "admin",
      password: creds[:password] || "admin"
    )
  end

  scope "/admin", ComnetWebsocketWeb.Admin do
    pipe_through [:browser, :admin_auth]

    get "/", DashboardController, :index

    get "/users", UserController, :index
    get "/users/create", UserController, :create
    post "/users", UserController, :store
    get "/users/:id/edit", UserController, :edit
    patch "/users/:id", UserController, :update
    delete "/users/:id", UserController, :delete
    post "/users/:id/generate_otp", UserController, :generate_otp
    post "/users/:id/regenerate_token", UserController, :regenerate_token
    post "/users/:id/shellies", UserController, :assign_shelly
    delete "/users/:id/shellies/:shelly_id", UserController, :remove_shelly

    get "/shellies", ShellyController, :index
    get "/shellies/create", ShellyController, :new
    post "/shellies", ShellyController, :create
    get "/shellies/:id/edit", ShellyController, :edit
    patch "/shellies/:id", ShellyController, :update
    delete "/shellies/:id", ShellyController, :delete

    get "/devices", DeviceController, :index

    get "/alerts", AlertController, :index

    get "/notifications", NotificationController, :index
    post "/notifications", NotificationController, :send_notification
  end

  get "/_matrix/push/v1/notify", ComnetWebsocketWeb.UnifiedPushController, :check
  post "/_matrix/push/v1/notify", ComnetWebsocketWeb.UnifiedPushController, :send_notification

  scope "/api", ComnetWebsocketWeb do
    pipe_through :api

    scope "/v1" do
      post "/auth/verify_otp", AuthController, :verify_otp

      get "/shellies", ShellyController, :index
      post "/alert/toggle", AlertController, :toggle_all_alerts
      post "/alert/:shelly_id/toggle", AlertController, :toggle_alert

      post "/notification/send", NotificationController, :send_notification
      post "/notification/send_old", NotificationController, :send_old_notification

      get "/notification/device/:device_id",
          NotificationController,
          :get_notifications_by_device_id

      get "/connection/active", ConnectionController, :active_connections
      get "/connection/active/users", ConnectionController, :active_users

      post "/unified_push/:id/send",
           UnifiedPushController,
           :send_notification

      post "/unified_push_app", UnifiedPushAppController, :create
      delete "/unified_push_app/:device_id/:connector_token", UnifiedPushAppController, :delete
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
    # import Plug.BasicAuth

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
