defmodule ComnetWebsocketWeb.AlertController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.AlertService

  plug ComnetWebsocketWeb.Plugs.UserAccessTokenAuth

  @doc """
  Toggles a specific shelly for the authenticated user.
  Stops the running dispatch task (turns relay off) if one is active,
  otherwise starts a new alert cycle (turns relay on).
  """
  @spec toggle_alert(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def toggle_alert(conn, %{"shelly_id" => shelly_id}) do
    if conn.assigns.current_user.is_banned do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Account is banned"})
    else
      do_toggle_alert(conn, shelly_id)
    end
  end

  defp do_toggle_alert(conn, shelly_id) do
    case AlertService.toggle_shelly(conn.assigns.current_user, shelly_id) do
      {:ok, :stopped} ->
        json(conn, %{success: true, action: "stopped", shelly_id: shelly_id})

      {:ok, alert} ->
        json(conn, %{
          success: true,
          action: "started",
          alert_id: alert.id,
          shelly_id: alert.shelly_id,
          triggered_at: alert.inserted_at
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Shelly not found"})

      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You do not have access to this shelly"})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to record alert"})
    end
  end

  @doc """
  Toggles all shellies assigned to the authenticated user.
  Each shelly is independently stopped (if running) or started (if idle).
  """
  @spec toggle_all_alerts(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def toggle_all_alerts(conn, _params) do
    if conn.assigns.current_user.is_banned do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Account is banned"})
    else
      do_toggle_all_alerts(conn)
    end
  end

  defp do_toggle_all_alerts(conn) do
    results =
      conn.assigns.current_user
      |> AlertService.toggle_all_shellies()
      |> Enum.map(fn %{shelly_id: shelly_id, shelly_name: name, result: result} ->
        case result do
          {:ok, :stopped} ->
            %{shelly_id: shelly_id, shelly_name: name, success: true, action: "stopped"}

          {:ok, alert} ->
            %{
              shelly_id: shelly_id,
              shelly_name: name,
              success: true,
              action: "started",
              alert_id: alert.id
            }

          {:error, reason} ->
            %{shelly_id: shelly_id, shelly_name: name, success: false, error: inspect(reason)}
        end
      end)

    json(conn, %{data: results})
  end
end
