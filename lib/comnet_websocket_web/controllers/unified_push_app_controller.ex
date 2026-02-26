defmodule ComnetWebsocketWeb.UnifiedPushAppController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.UnifiedPushAppService

  def create(conn, %{
        "app_id" => app_id,
        "connector_token" => connector_token,
        "device_id" => device_id
      }) do
    case UnifiedPushAppService.create_unified_push_app(%{
           app_id: app_id,
           connector_token: connector_token,
           device_id: device_id
         }) do
      {:ok, unified_push_app} ->
        json(conn, %{
          success: true,
          message: "Unified push app created successfully",
          url: "https://#{conn.host}/api/v1/unified_push/#{unified_push_app.id}/send"
        })

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false
        })
    end
  end

  def delete(conn, params) do
    device_id = params["device_id"] || Map.get(conn.path_params, "device_id")
    connector_token = params["connector_token"] || Map.get(conn.path_params, "connector_token")

    if !device_id || !connector_token do
      conn
      |> put_status(:bad_request)
      |> json(%{
        success: false,
        error: "Missing device_id or connector_token"
      })
    else
      case UnifiedPushAppService.delete_unified_push_app(%{
             device_id: device_id,
             connector_token: connector_token
           }) do
        {:ok, unified_push_app} ->
          json(conn, %{
            success: true,
            app_id: unified_push_app.app_id,
            message: "Unified push app deleted successfully"
          })

        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{
            success: false,
            error: "Unified push app not found"
          })
      end
    end
  end

  def matrix_notify_check(conn, _params) do
    json(conn, %{
      unifiedpush: %{
        gateway: "matrix"
      }
    })
  end
end
