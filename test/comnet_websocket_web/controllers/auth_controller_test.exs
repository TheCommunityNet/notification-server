defmodule ComnetWebsocketWeb.AuthControllerTest do
  use ComnetWebsocketWeb.ConnCase, async: true

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.User

  defp create_user_with_otp(attrs \\ %{}) do
    {:ok, user} =
      %User{}
      |> User.admin_create_changeset(%{name: Map.get(attrs, :name, "Test User")})
      |> Repo.insert()

    {:ok, user} = User.generate_otp_changeset(user) |> Repo.update()
    user
  end

  describe "POST /api/v1/auth/verify_otp" do
    test "returns access_token with valid otp_token and device_id", %{conn: conn} do
      user = create_user_with_otp()

      conn =
        post(conn, ~p"/api/v1/auth/verify_otp", %{
          "otp_token" => user.otp_token,
          "device_id" => "my-device-001"
        })

      assert %{"access_token" => access_token} = json_response(conn, 200)
      assert access_token == user.access_token
    end

    test "clears otp_token after successful verification", %{conn: conn} do
      user = create_user_with_otp()

      post(conn, ~p"/api/v1/auth/verify_otp", %{
        "otp_token" => user.otp_token,
        "device_id" => "my-device-001"
      })

      updated = Repo.get!(User, user.id)
      assert updated.otp_token == nil
    end

    test "updates device_id after successful verification", %{conn: conn} do
      user = create_user_with_otp()
      new_device_id = "my-device-999"

      post(conn, ~p"/api/v1/auth/verify_otp", %{
        "otp_token" => user.otp_token,
        "device_id" => new_device_id
      })

      updated = Repo.get!(User, user.id)
      assert updated.device_id == new_device_id
    end

    test "returns 401 with invalid otp_token", %{conn: conn} do
      conn =
        post(conn, ~p"/api/v1/auth/verify_otp", %{
          "otp_token" => "INVALID",
          "device_id" => "my-device-001"
        })

      assert %{"error" => "Invalid or expired OTP token"} = json_response(conn, 401)
    end

    test "returns 401 after otp_token is already consumed", %{conn: conn} do
      user = create_user_with_otp()

      post(conn, ~p"/api/v1/auth/verify_otp", %{
        "otp_token" => user.otp_token,
        "device_id" => "device-first"
      })

      conn2 = Phoenix.ConnTest.build_conn()

      conn2 =
        post(conn2, ~p"/api/v1/auth/verify_otp", %{
          "otp_token" => user.otp_token,
          "device_id" => "device-second"
        })

      assert %{"error" => "Invalid or expired OTP token"} = json_response(conn2, 401)
    end

    test "returns 400 when otp_token is missing", %{conn: conn} do
      conn =
        post(conn, ~p"/api/v1/auth/verify_otp", %{
          "device_id" => "my-device-001"
        })

      assert %{"error" => "otp_token and device_id are required"} = json_response(conn, 400)
    end

    test "returns 400 when device_id is missing", %{conn: conn} do
      user = create_user_with_otp()

      conn =
        post(conn, ~p"/api/v1/auth/verify_otp", %{
          "otp_token" => user.otp_token
        })

      assert %{"error" => "otp_token and device_id are required"} = json_response(conn, 400)
    end

    test "returns 400 when body is empty", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/auth/verify_otp", %{})

      assert %{"error" => "otp_token and device_id are required"} = json_response(conn, 400)
    end
  end
end
