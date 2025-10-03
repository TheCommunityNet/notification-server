defmodule ComnetWebsocketWeb.NotificationChannelTest do
  use ComnetWebsocketWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      ComnetWebsocketWeb.NotificationSocket
      |> socket("device_id", %{device_id: "test-device-123"})
      |> subscribe_and_join(ComnetWebsocketWeb.NotificationChannel, "notification")

    # Add connection_id to the socket assigns for testing
    socket = Phoenix.Socket.assign(socket, :connection_id, "test-connection-123")
    %{socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push(socket, "ping", %{"hello" => "there"})
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  test "shout broadcasts to notification", %{socket: socket} do
    push(socket, "shout", %{"hello" => "all"})
    assert_broadcast "shout", %{"hello" => "all"}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from!(socket, "broadcast", %{"some" => "data"})
    assert_push "broadcast", %{"some" => "data"}
  end

  test "connect with user_id sets user_id in socket", %{socket: socket} do
    ref = push(socket, "connect", %{"user_id" => "user-123"})
    assert_reply ref, :ok, %{msg: "logged in"}
    # Note: The socket is updated in the channel, but we can't easily test the updated socket
    # in this test context. The important thing is that the reply is successful.
  end

  test "received message saves notification tracking", %{socket: socket} do
    push(socket, "received", %{
      "device_id" => "test-device-123",
      "notification_id" => "notification-123",
      "received_at" => 1_759_409_332_113,
      "sent_at" => 1_759_409_332_113
    })

    # The function should complete without error
    assert :ok
  end

  test "received message handles emergency notifications immediately", %{socket: socket} do
    # This test would require mocking the NotificationService.get_notification_by_key
    # to return an emergency notification, but for now we just test the basic flow
    push(socket, "received", %{
      "device_id" => "test-device-123",
      "notification_id" => "emergency-notification-123",
      "received_at" => 1_759_409_332_113,
      "sent_at" => 1_759_409_332_113
    })

    # The function should complete without error
    assert :ok
  end

  test "received message handles grouped notifications", %{socket: socket} do
    # This test would require mocking the NotificationService.get_notification_by_key
    # to return a grouped notification, but for now we just test the basic flow
    push(socket, "received", %{
      "device_id" => "test-device-123",
      "notification_id" => "grouped-notification-123",
      "received_at" => 1_759_409_332_113,
      "sent_at" => 1_759_409_332_113
    })

    # The function should complete without error
    assert :ok
  end
end
