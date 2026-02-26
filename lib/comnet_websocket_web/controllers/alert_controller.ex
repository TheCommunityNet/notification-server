defmodule ComnetWebsocketWeb.AlertController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.AlertService

  plug ComnetWebsocketWeb.Plugs.UserAccessTokenAuth

  @doc """
  Triggers an alert on a specific shelly.
  The shelly must be assigned to the authenticated user.
  The trigger is recorded in the database.
  """
  @spec send_alert(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send_alert(conn, %{"shelly_id" => shelly_id}) do
    case AlertService.trigger_shelly(conn.assigns.current_user, shelly_id) do
      {:ok, alert} ->
        json(conn, %{
          success: true,
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
  Triggers alerts on all shellies assigned to the authenticated user.
  Each trigger is recorded in the database.
  """
  @spec send_all_alerts(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def send_all_alerts(conn, _params) do
    results =
      conn.assigns.current_user
      |> AlertService.trigger_all_shellies()
      |> Enum.map(fn %{shelly_id: shelly_id, shelly_name: name, result: result} ->
        case result do
          {:ok, alert} ->
            %{shelly_id: shelly_id, shelly_name: name, success: true, alert_id: alert.id}

          {:error, reason} ->
            %{shelly_id: shelly_id, shelly_name: name, success: false, error: inspect(reason)}
        end
      end)

    json(conn, %{data: results})
  end
end
