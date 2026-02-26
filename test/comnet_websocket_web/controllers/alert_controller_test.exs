defmodule ComnetWebsocketWeb.AlertControllerTest do
  use ComnetWebsocketWeb.ConnCase, async: true

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{User, Shelly, ShellyAlert}
  alias ComnetWebsocket.Services.UserService

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp create_user(name \\ "Test User") do
    {:ok, user} =
      %User{}
      |> User.admin_create_changeset(%{name: name})
      |> Repo.insert()

    user
  end

  defp create_shelly(attrs \\ %{}) do
    {:ok, shelly} =
      %Shelly{}
      |> Shelly.changeset(%{
        name: Map.get(attrs, :name, "Test Shelly"),
        # 127.0.0.1 ensures connection refused instantly — dispatch result is discarded
        ip_address: Map.get(attrs, :ip_address, "127.0.0.1")
      })
      |> Repo.insert()

    shelly
  end

  defp assign_shelly(user, shelly) do
    {:ok, _} = UserService.assign_shelly(user, to_string(shelly.id))
    :ok
  end

  defp auth_conn(conn, user) do
    put_req_header(conn, "authorization", "Bearer #{user.access_token}")
  end

  defp alert_count, do: Repo.aggregate(ShellyAlert, :count)

  # ── POST /api/v1/alert/:shelly_id/send ────────────────────────────────────────

  describe "POST /api/v1/alert/:shelly_id/send" do
    test "records alert and returns success for owned shelly", %{conn: conn} do
      user = create_user()
      shelly = create_shelly(%{name: "Living Room"})
      assign_shelly(user, shelly)

      conn =
        conn
        |> auth_conn(user)
        |> post(~p"/api/v1/alert/#{shelly.id}/send")

      assert %{
               "success" => true,
               "alert_id" => alert_id,
               "shelly_id" => shelly_id,
               "triggered_at" => triggered_at
             } = json_response(conn, 200)

      assert is_binary(alert_id)
      assert shelly_id == to_string(shelly.id)
      assert is_binary(triggered_at)
    end

    test "saves the alert record in the database", %{conn: conn} do
      user = create_user()
      shelly = create_shelly()
      assign_shelly(user, shelly)

      before_count = alert_count()

      conn
      |> auth_conn(user)
      |> post(~p"/api/v1/alert/#{shelly.id}/send")

      assert alert_count() == before_count + 1

      alert = Repo.get_by!(ShellyAlert, shelly_id: shelly.id, user_id: user.id)
      assert alert.shelly_id == shelly.id
      assert alert.user_id == user.id
    end

    test "returns 403 when shelly exists but is not assigned to the user", %{conn: conn} do
      user = create_user("User A")
      other_user = create_user("User B")
      shelly = create_shelly()
      assign_shelly(other_user, shelly)

      conn =
        conn
        |> auth_conn(user)
        |> post(~p"/api/v1/alert/#{shelly.id}/send")

      assert %{"error" => "You do not have access to this shelly"} = json_response(conn, 403)
    end

    test "does not record an alert when user is forbidden", %{conn: conn} do
      user = create_user("User A")
      other_user = create_user("User B")
      shelly = create_shelly()
      assign_shelly(other_user, shelly)

      before_count = alert_count()

      conn
      |> auth_conn(user)
      |> post(~p"/api/v1/alert/#{shelly.id}/send")

      assert alert_count() == before_count
    end

    test "returns 404 when shelly does not exist", %{conn: conn} do
      user = create_user()
      fake_id = Ecto.UUID.generate()

      conn =
        conn
        |> auth_conn(user)
        |> post(~p"/api/v1/alert/#{fake_id}/send")

      assert %{"error" => "Shelly not found"} = json_response(conn, 404)
    end

    test "returns 401 without authorization header", %{conn: conn} do
      shelly = create_shelly()
      conn = post(conn, ~p"/api/v1/alert/#{shelly.id}/send")

      assert conn.status == 401
    end

    test "returns 401 with invalid token", %{conn: conn} do
      shelly = create_shelly()

      conn =
        conn
        |> put_req_header("authorization", "Bearer wrong-token")
        |> post(~p"/api/v1/alert/#{shelly.id}/send")

      assert conn.status == 401
    end
  end

  # ── POST /api/v1/alert/send ───────────────────────────────────────────────────

  describe "POST /api/v1/alert/send" do
    test "triggers all assigned shellies and returns results", %{conn: conn} do
      user = create_user()
      shelly_a = create_shelly(%{name: "Shelly A"})
      shelly_b = create_shelly(%{name: "Shelly B"})
      assign_shelly(user, shelly_a)
      assign_shelly(user, shelly_b)

      conn = conn |> auth_conn(user) |> post(~p"/api/v1/alert/send")

      assert %{"data" => results} = json_response(conn, 200)
      assert length(results) == 2

      Enum.each(results, fn r ->
        assert r["success"] == true
        assert is_binary(r["alert_id"])
        assert r["shelly_id"] in [to_string(shelly_a.id), to_string(shelly_b.id)]
      end)
    end

    test "saves an alert record for each shelly", %{conn: conn} do
      user = create_user()
      shelly_a = create_shelly(%{name: "A"})
      shelly_b = create_shelly(%{name: "B"})
      assign_shelly(user, shelly_a)
      assign_shelly(user, shelly_b)

      before_count = alert_count()

      conn |> auth_conn(user) |> post(~p"/api/v1/alert/send")

      assert alert_count() == before_count + 2
    end

    test "returns empty data when user has no shellies", %{conn: conn} do
      user = create_user()

      conn = conn |> auth_conn(user) |> post(~p"/api/v1/alert/send")

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "only triggers shellies assigned to the authenticated user", %{conn: conn} do
      user = create_user("User A")
      other_user = create_user("User B")
      my_shelly = create_shelly(%{name: "Mine"})
      other_shelly = create_shelly(%{name: "Theirs"})
      assign_shelly(user, my_shelly)
      assign_shelly(other_user, other_shelly)

      conn = conn |> auth_conn(user) |> post(~p"/api/v1/alert/send")

      assert %{"data" => results} = json_response(conn, 200)
      assert length(results) == 1
      assert hd(results)["shelly_id"] == to_string(my_shelly.id)
    end

    test "returns 401 without authorization header", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/alert/send")

      assert conn.status == 401
    end

    test "returns 401 with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer bad-token")
        |> post(~p"/api/v1/alert/send")

      assert conn.status == 401
    end
  end
end
