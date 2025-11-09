defmodule ComnetWebsocketWeb.UnifiedPushController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.UnifiedPushAppService

  def send_notification(
        conn,
        %{
          "id" => id
        } = params
      ) do
    case UnifiedPushAppService.find_unified_push_app_by_id(id) do
      {:ok, _} ->
        IO.inspect(params, label: "unified push")

        json(conn, %{
          success: true,
          message: "Unified push notification sent successfully"
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
