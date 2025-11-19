defmodule ComnetWebsocketWeb.UnifiedPushControllerTest do
  use ComnetWebsocketWeb.ConnCase

  import Ecto.Query
  alias ComnetWebsocket.Services.UnifiedPushAppService
  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{Notification, NotificationTracking}

  describe "GET /_matrix/push/v1/notify" do
    test "returns unifiedpush gateway info", %{conn: conn} do
      conn = get(conn, ~p"/_matrix/push/v1/notify")

      assert %{
               "unifiedpush" => %{
                 "gateway" => "matrix"
               }
             } = json_response(conn, 200)
    end
  end

  describe "POST /_matrix/push/v1/notify" do
    setup do
      # Create a unified push app for testing
      attrs = %{
        app_id: "im.vector.app",
        connector_token: Ecto.UUID.generate(),
        device_id: "device123"
      }

      {:ok, unified_push_app} = UnifiedPushAppService.create_unified_push_app(attrs)

      %{unified_push_app: unified_push_app}
    end

    test "processes valid Matrix notification and returns empty rejected list", %{
      conn: conn,
      unified_push_app: unified_push_app
    } do
      pushkey = "api/v1/unified_push/#{unified_push_app.id}/send"

      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => [
            %{
              "app_id" => "im.vector.app",
              "pushkey" => pushkey,
              "data" => %{}
            }
          ]
        }
      }

      # Count notifications before
      notification_count_before = Repo.aggregate(Notification, :count, :id)

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => []} = json_response(conn, 200)

      # Verify notification was saved to database
      notification_count_after = Repo.aggregate(Notification, :count, :id)
      assert notification_count_after == notification_count_before + 1

      # Verify notification details via tracking record
      saved_tracking =
        Repo.one(
          from nt in NotificationTracking,
            where: nt.device_id == ^unified_push_app.device_id,
            order_by: [desc: nt.inserted_at],
            limit: 1
        )

      assert saved_tracking != nil
      assert saved_tracking.device_id == unified_push_app.device_id

      # Verify notification details
      saved_notification = Repo.get_by(Notification, key: saved_tracking.notification_key)

      assert saved_notification != nil
      assert saved_notification.type == "device"
      assert saved_notification.category == "matrix"
      assert saved_notification.payload["app_id"] == unified_push_app.app_id
      assert saved_notification.payload["connector_token"] == unified_push_app.connector_token
    end

    test "rejects pushkey when unified push app not found", %{conn: conn} do
      non_existent_id = Ecto.UUID.generate()
      pushkey = "api/v1/unified_push/#{non_existent_id}/send"

      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => [
            %{
              "app_id" => "im.vector.app",
              "pushkey" => pushkey,
              "data" => %{}
            }
          ]
        }
      }

      # Count notifications before
      notification_count_before = Repo.aggregate(Notification, :count, :id)

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => rejected} = json_response(conn, 200)
      assert pushkey in rejected

      # Verify no notification was saved when unified push app not found
      notification_count_after = Repo.aggregate(Notification, :count, :id)
      assert notification_count_after == notification_count_before
    end

    test "rejects invalid pushkey format", %{conn: conn} do
      invalid_pushkey = "invalid/path/format"

      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => [
            %{
              "app_id" => "im.vector.app",
              "pushkey" => invalid_pushkey,
              "data" => %{}
            }
          ]
        }
      }

      # Count notifications before
      notification_count_before = Repo.aggregate(Notification, :count, :id)

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => rejected} = json_response(conn, 200)
      assert invalid_pushkey in rejected

      # Verify no notification was saved when pushkey is invalid
      notification_count_after = Repo.aggregate(Notification, :count, :id)
      assert notification_count_after == notification_count_before
    end

    test "handles multiple devices with some valid and some invalid", %{
      conn: conn,
      unified_push_app: unified_push_app
    } do
      valid_pushkey = "api/v1/unified_push/#{unified_push_app.id}/send"
      invalid_pushkey = "invalid/path"

      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => [
            %{
              "app_id" => "im.vector.app",
              "pushkey" => valid_pushkey,
              "data" => %{}
            },
            %{
              "app_id" => "im.vector.app",
              "pushkey" => invalid_pushkey,
              "data" => %{}
            }
          ]
        }
      }

      # Count notifications before
      notification_count_before = Repo.aggregate(Notification, :count, :id)

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => rejected} = json_response(conn, 200)
      assert invalid_pushkey in rejected
      refute valid_pushkey in rejected

      # Verify notification was saved for valid pushkey only
      notification_count_after = Repo.aggregate(Notification, :count, :id)
      assert notification_count_after == notification_count_before + 1
    end

    test "handles pushkey with full URL", %{conn: conn, unified_push_app: unified_push_app} do
      pushkey = "https://example.com/api/v1/unified_push/#{unified_push_app.id}/send"

      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => [
            %{
              "app_id" => "im.vector.app",
              "pushkey" => pushkey,
              "data" => %{}
            }
          ]
        }
      }

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => []} = json_response(conn, 200)
    end

    test "handles pushkey with leading slash", %{conn: conn, unified_push_app: unified_push_app} do
      pushkey = "/api/v1/unified_push/#{unified_push_app.id}/send"

      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => [
            %{
              "app_id" => "im.vector.app",
              "pushkey" => pushkey,
              "data" => %{}
            }
          ]
        }
      }

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => []} = json_response(conn, 200)
    end

    test "returns error for invalid notification format", %{conn: conn} do
      invalid_notification = %{
        "invalid" => "data"
      }

      conn = post(conn, ~p"/_matrix/push/v1/notify", invalid_notification)

      assert %{"error" => "Invalid notification format"} = json_response(conn, 400)
    end

    test "returns error when notification is missing", %{conn: conn} do
      conn = post(conn, ~p"/_matrix/push/v1/notify", %{})

      assert %{"error" => "Invalid notification format"} = json_response(conn, 400)
    end

    test "handles notification without devices array", %{conn: conn} do
      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          }
        }
      }

      # Count notifications before
      notification_count_before = Repo.aggregate(Notification, :count, :id)

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => []} = json_response(conn, 200)

      # Verify no notification was saved when no devices
      notification_count_after = Repo.aggregate(Notification, :count, :id)
      assert notification_count_after == notification_count_before
    end

    test "handles notification with empty devices array", %{conn: conn} do
      notification = %{
        "notification" => %{
          "event_id" => "event123",
          "room_id" => "!room123:example.com",
          "type" => "m.room.message",
          "sender" => "@user:example.com",
          "content" => %{
            "body" => "Hello, world!",
            "msgtype" => "m.text"
          },
          "devices" => []
        }
      }

      # Count notifications before
      notification_count_before = Repo.aggregate(Notification, :count, :id)

      conn = post(conn, ~p"/_matrix/push/v1/notify", notification)

      assert %{"rejected" => []} = json_response(conn, 200)

      # Verify no notification was saved when devices array is empty
      notification_count_after = Repo.aggregate(Notification, :count, :id)
      assert notification_count_after == notification_count_before
    end
  end
end
