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

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: changeset
        })
    end
  end

  def delete(conn, %{
        "connector_token" => connector_token,
        "device_id" => device_id
      }) do
    case UnifiedPushAppService.delete_unified_push_app(%{
           connector_token: connector_token,
           device_id: device_id
         }) do
      {:ok, unified_push_app} ->
        json(conn, %{
          success: true,
          app_id: unified_push_app.app_id,
          message: "Unified push app deleted successfully"
        })
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
