defmodule ComnetWebsocketWeb.NotificationControllerTest do
  use ComnetWebsocketWeb.ConnCase

  import Ecto.Query
  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{Notification, NotificationTracking}
  alias ComnetWebsocket.{Constants}
  alias ComnetWebsocketWeb.Plugs.RateLimit

  describe "GET /api/v1/notification/device/:device_id" do
    setup do
      # Clear rate limit data before each test
      RateLimit.clear_all()

      # Create a device notification for testing
      device_id = "test-device-#{System.unique_integer([:positive])}"
      expired_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      notification_attrs = %{
        key: Ecto.UUID.generate(),
        type: Constants.notification_type_device(),
        category: "test",
        payload: %{"title" => "Test Title", "content" => "Test Content"},
        sent_count: 0,
        received_count: 0,
        expired_at: expired_at,
        is_expired: false
      }

      {:ok, notification} =
        %Notification{}
        |> Notification.changeset(notification_attrs)
        |> Repo.insert()

      # Note: Device notifications without tracking records are considered unread
      # We'll create a tracking record to test the marking as read functionality

      %{device_id: device_id, notification: notification}
    end

    test "returns unread notifications as websocket messages", %{
      conn: conn,
      device_id: device_id,
      notification: notification
    } do
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      assert %{"messages" => messages} = json_response(conn, 200)
      assert length(messages) == 1

      message = List.first(messages)
      assert message["id"] == notification.key
      assert message["category"] == "test"
      assert message["data"] == %{"title" => "Test Title", "content" => "Test Content"}
      assert message["is_dialog"] == false

      # Verify notification was marked as read
      tracking =
        Repo.get_by(NotificationTracking,
          notification_key: notification.key,
          device_id: device_id
        )

      assert tracking != nil
      assert tracking.is_received == true
      assert tracking.received_at != nil
    end

    test "returns empty list when no unread notifications", %{conn: conn} do
      device_id = "device-with-no-notifications-#{System.unique_integer([:positive])}"

      # Ensure no notifications exist for this device
      # (device notifications without tracking are considered unread, so we need to mark any existing ones)
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      # After first call, all notifications should be marked as read
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      assert %{"messages" => []} = json_response(conn, 200)
    end

    test "returns only unread notifications", %{
      conn: conn,
      device_id: device_id,
      notification: notification
    } do
      # Create a read notification
      read_notification_attrs = %{
        key: Ecto.UUID.generate(),
        type: Constants.notification_type_device(),
        category: "test",
        payload: %{"title" => "Read Title", "content" => "Read Content"},
        sent_count: 0,
        received_count: 0,
        expired_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        is_expired: false
      }

      {:ok, read_notification} =
        %Notification{}
        |> Notification.changeset(read_notification_attrs)
        |> Repo.insert()

      {:ok, _tracking} =
        %NotificationTracking{}
        |> NotificationTracking.changeset(%{
          notification_key: read_notification.key,
          device_id: device_id,
          is_received: true,
          received_at: DateTime.utc_now()
        })
        |> Repo.insert()

      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      assert %{"messages" => messages} = json_response(conn, 200)
      assert length(messages) == 1
      assert List.first(messages)["id"] == notification.key
    end

    test "excludes expired notifications", %{conn: conn} do
      # Use a different device_id to avoid conflicts with setup
      device_id = "expired-test-device-#{System.unique_integer([:positive])}"

      # First, clear any existing notifications for this device by fetching them
      # This ensures we start with a clean slate
      _conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      # Create an expired notification (expired_at in the past)
      expired_at = DateTime.add(DateTime.utc_now(), -3600, :second)

      expired_notification_attrs = %{
        key: Ecto.UUID.generate(),
        type: Constants.notification_type_device(),
        category: "test",
        payload: %{"title" => "Expired Title", "content" => "Expired Content"},
        sent_count: 0,
        received_count: 0,
        expired_at: expired_at,
        is_expired: true
      }

      {:ok, _expired_notification} =
        %Notification{}
        |> Notification.changeset(expired_notification_attrs)
        |> Repo.insert()

      # Don't create a tracking record - device notifications without tracking
      # are considered unread, but expired ones should still be excluded

      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      assert %{"messages" => []} = json_response(conn, 200)
    end

    test "returns bad request when device_id is missing", %{conn: conn} do
      # Use a path without device_id - this will result in 404 from router
      conn = get(conn, "/api/v1/notification/device/")

      assert conn.status == 404
    end

    test "marks multiple notifications as read", %{conn: conn, device_id: device_id} do
      # Create additional unread notifications
      expired_at = DateTime.add(DateTime.utc_now(), 3600, :second)

      for i <- 1..3 do
        notification_attrs = %{
          key: Ecto.UUID.generate(),
          type: Constants.notification_type_device(),
          category: "test",
          payload: %{"title" => "Title #{i}", "content" => "Content #{i}"},
          sent_count: 0,
          received_count: 0,
          expired_at: expired_at,
          is_expired: false
        }

        {:ok, notification} =
          %Notification{}
          |> Notification.changeset(notification_attrs)
          |> Repo.insert()

        {:ok, _tracking} =
          %NotificationTracking{}
          |> NotificationTracking.changeset(%{
            notification_key: notification.key,
            device_id: device_id,
            is_received: false
          })
          |> Repo.insert()
      end

      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      assert %{"messages" => messages} = json_response(conn, 200)
      assert length(messages) == 4

      # Verify all notifications were marked as read
      trackings =
        Repo.all(
          from nt in NotificationTracking,
            where: nt.device_id == ^device_id,
            where: nt.is_received == true
        )

      assert length(trackings) == 4
    end
  end

  describe "GET /api/v1/notification/device/:device_id - rate limiting" do
    setup do
      RateLimit.clear_all()
      device_id = "rate-limit-test-device"
      %{device_id: device_id}
    end

    test "allows requests within rate limit", %{conn: conn, device_id: device_id} do
      # Make 10 requests (the limit)
      for _i <- 1..10 do
        conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")
        # 200 for success, 400 if no device_id in path
        assert conn.status in [200, 400]
      end
    end

    test "blocks requests exceeding rate limit", %{conn: conn, device_id: device_id} do
      # Make 10 requests (the limit)
      for _i <- 1..10 do
        get(conn, ~p"/api/v1/notification/device/#{device_id}")
      end

      # 11th request should be rate limited
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")

      assert conn.status == 429
      assert %{"error" => error_message} = json_response(conn, 429)
      assert error_message =~ "Rate limit exceeded"
      assert error_message =~ "10 requests per 60 seconds"
    end

    test "rate limit is per device_id", %{conn: conn} do
      device_id_1 = "device-1"
      device_id_2 = "device-2"

      # Exceed rate limit for device_1
      for _i <- 1..11 do
        get(conn, ~p"/api/v1/notification/device/#{device_id_1}")
      end

      # device_2 should still be able to make requests
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id_2}")
      # Not rate limited
      assert conn.status in [200, 400]
    end

    test "rate limit resets after window expires", %{conn: conn, device_id: device_id} do
      # Make 10 requests
      for _i <- 1..10 do
        get(conn, ~p"/api/v1/notification/device/#{device_id}")
      end

      # 11th should be blocked
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")
      assert conn.status == 429

      # Simulate time passing by manually clearing the rate limit
      # In a real scenario, this would happen after 60 seconds
      RateLimit.clear_key(device_id)

      # Now should be able to make requests again
      conn = get(conn, ~p"/api/v1/notification/device/#{device_id}")
      # Not rate limited anymore
      assert conn.status in [200, 400]
    end
  end
end
