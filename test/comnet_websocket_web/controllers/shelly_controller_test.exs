defmodule ComnetWebsocketWeb.ShellyControllerTest do
  use ComnetWebsocketWeb.ConnCase, async: true

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{User, Shelly}
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

  # ── Tests ─────────────────────────────────────────────────────────────────────

  describe "GET /api/v1/shellies" do
    test "returns shellies assigned to the user", %{conn: conn} do
      user = create_user()
      shelly_a = create_shelly(%{name: "Alpha"})
      shelly_b = create_shelly(%{name: "Beta"})
      assign_shelly(user, shelly_a)
      assign_shelly(user, shelly_b)

      conn = conn |> auth_conn(user) |> get(~p"/api/v1/shellies")

      assert %{"data" => shellies} = json_response(conn, 200)
      assert length(shellies) == 2

      ids = Enum.map(shellies, & &1["id"])
      assert to_string(shelly_a.id) in ids
      assert to_string(shelly_b.id) in ids
    end

    test "returns only id and name fields", %{conn: conn} do
      user = create_user()
      shelly = create_shelly(%{name: "My Shelly"})
      assign_shelly(user, shelly)

      conn = conn |> auth_conn(user) |> get(~p"/api/v1/shellies")

      assert %{"data" => [item]} = json_response(conn, 200)
      assert Map.keys(item) |> Enum.sort() == ["id", "name"]
      assert item["name"] == "My Shelly"
    end

    test "returns shellies ordered by name", %{conn: conn} do
      user = create_user()
      assign_shelly(user, create_shelly(%{name: "Zulu"}))
      assign_shelly(user, create_shelly(%{name: "Alpha"}))
      assign_shelly(user, create_shelly(%{name: "Mike"}))

      conn = conn |> auth_conn(user) |> get(~p"/api/v1/shellies")

      assert %{"data" => shellies} = json_response(conn, 200)
      names = Enum.map(shellies, & &1["name"])
      assert names == ["Alpha", "Mike", "Zulu"]
    end

    test "returns empty list when user has no shellies", %{conn: conn} do
      user = create_user()

      conn = conn |> auth_conn(user) |> get(~p"/api/v1/shellies")

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "does not return shellies of other users", %{conn: conn} do
      user = create_user("User A")
      other_user = create_user("User B")
      shelly = create_shelly()
      assign_shelly(other_user, shelly)

      conn = conn |> auth_conn(user) |> get(~p"/api/v1/shellies")

      assert %{"data" => []} = json_response(conn, 200)
    end

    test "returns 401 without authorization header", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/shellies")

      assert conn.status == 401
    end

    test "returns 401 with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid-token")
        |> get(~p"/api/v1/shellies")

      assert conn.status == 401
    end

    test "returns 401 with malformed authorization header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "not-bearer-format")
        |> get(~p"/api/v1/shellies")

      assert conn.status == 401
    end
  end
end
