defmodule ComnetWebsocketWeb.AuthController do
  use ComnetWebsocketWeb, :controller

  alias ComnetWebsocket.Services.UserService

  @doc """
  Verifies an OTP token, updates the device_id, clears the OTP token,
  and returns the user's access_token.

  ## Parameters
  - `otp_token` - The one-time password token issued to the user
  - `device_id` - The device identifier to associate with the user

  ## Returns
  - `200` with `%{access_token: ...}` on success
  - `401` with error message if OTP token is invalid
  - `400` with error message if params are missing
  """
  @spec verify_otp(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def verify_otp(conn, %{"otp_token" => otp_token, "device_id" => device_id})
      when is_binary(otp_token) and is_binary(device_id) do
    case UserService.verify_otp(otp_token, device_id) do
      {:ok, user} ->
        json(conn, %{access_token: user.access_token})

      {:error, :invalid_otp} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid or expired OTP token"})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to update user"})
    end
  end

  def verify_otp(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "otp_token and device_id are required"})
  end
end
