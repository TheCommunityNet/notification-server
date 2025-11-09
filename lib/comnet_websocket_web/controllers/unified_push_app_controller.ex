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
        "app_id" => app_id,
        "connector_token" => connector_token,
        "device_id" => device_id
      }) do
    case UnifiedPushAppService.delete_unified_push_app(%{
           app_id: app_id,
           connector_token: connector_token,
           device_id: device_id
         }) do
      {:ok, _} ->
        json(conn, %{
          message: "Unified push app deleted successfully"
        })
    end
  end

  def matrix_notify(conn, _params) do
    # Matrix Push Gateway expects a response with rejected pushkeys
    # For now, we accept all notifications and return empty rejected array
    json(conn, %{
      rejected: []
    })
  end
end
