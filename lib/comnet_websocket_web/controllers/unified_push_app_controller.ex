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
      {:ok, _} ->
        json(conn, %{
          success: true,
          message: "Unified push app created successfully",
          url: "#{conn.request_path}/#{app_id}/#{connector_token}/send"
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
end
