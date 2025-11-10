defmodule ComnetWebsocket.Services.UnifiedPushAppServiceTest do
  use ComnetWebsocket.DataCase

  alias ComnetWebsocket.Services.UnifiedPushAppService
  alias ComnetWebsocket.Models.UnifiedPushApp

  describe "create_unified_push_app/1" do
    test "creates a unified push app with valid attributes" do
      attrs = %{
        app_id: "im.vector.app",
        connector_token: Ecto.UUID.generate(),
        device_id: "device123"
      }

      assert {:ok, %UnifiedPushApp{} = unified_push_app} =
               UnifiedPushAppService.create_unified_push_app(attrs)

      assert unified_push_app.app_id == attrs.app_id
      assert unified_push_app.connector_token == attrs.connector_token
      assert unified_push_app.device_id == attrs.device_id
    end

    test "returns error with invalid attributes" do
      attrs = %{app_id: "im.vector.app"}

      assert {:error, %Ecto.Changeset{} = changeset} =
               UnifiedPushAppService.create_unified_push_app(attrs)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).connector_token
      assert "can't be blank" in errors_on(changeset).device_id
    end

    test "returns error when app_id and connector_token combination already exists" do
      attrs = %{
        app_id: "im.vector.app",
        connector_token: "token123",
        device_id: "device123"
      }

      assert {:ok, _} = UnifiedPushAppService.create_unified_push_app(attrs)

      # Try to create another with same app_id and connector_token
      assert {:error, %Ecto.Changeset{} = changeset} =
               UnifiedPushAppService.create_unified_push_app(attrs)

      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).app_id
    end

    test "allows same app_id with different connector_token" do
      attrs1 = %{
        app_id: "im.vector.app",
        connector_token: "token1",
        device_id: "device1"
      }

      attrs2 = %{
        app_id: "im.vector.app",
        connector_token: "token2",
        device_id: "device2"
      }

      assert {:ok, _} = UnifiedPushAppService.create_unified_push_app(attrs1)
      assert {:ok, _} = UnifiedPushAppService.create_unified_push_app(attrs2)
    end
  end

  describe "find_unified_push_app_by_id/1" do
    test "returns unified push app when found" do
      attrs = %{
        app_id: "im.vector.app",
        connector_token: Ecto.UUID.generate(),
        device_id: "device123"
      }

      assert {:ok, created_app} = UnifiedPushAppService.create_unified_push_app(attrs)
      assert {:ok, found_app} = UnifiedPushAppService.find_unified_push_app_by_id(created_app.id)
      assert found_app.id == created_app.id
      assert found_app.app_id == attrs.app_id
    end

    test "returns error when not found" do
      non_existent_id = Ecto.UUID.generate()

      assert {:error, :not_found} =
               UnifiedPushAppService.find_unified_push_app_by_id(non_existent_id)
    end
  end

  describe "find_unified_push_app_by_pushkey/1" do
    test "finds unified push app by app_id" do
      attrs = %{
        app_id: "im.vector.app",
        connector_token: Ecto.UUID.generate(),
        device_id: "device123"
      }

      assert {:ok, _} = UnifiedPushAppService.create_unified_push_app(attrs)

      assert {:ok, found_app} =
               UnifiedPushAppService.find_unified_push_app_by_pushkey("im.vector.app")

      assert found_app.app_id == "im.vector.app"
    end

    test "finds unified push app by connector_token" do
      connector_token = Ecto.UUID.generate()

      attrs = %{
        app_id: "im.vector.app",
        connector_token: connector_token,
        device_id: "device123"
      }

      assert {:ok, _} = UnifiedPushAppService.create_unified_push_app(attrs)

      assert {:ok, found_app} =
               UnifiedPushAppService.find_unified_push_app_by_pushkey(connector_token)

      assert found_app.connector_token == connector_token
    end

    test "returns error when pushkey not found" do
      assert {:error, :not_found} =
               UnifiedPushAppService.find_unified_push_app_by_pushkey("nonexistent")
    end
  end

  describe "delete_unified_push_app/1" do
    test "deletes unified push app with matching connector_token and device_id" do
      attrs = %{
        app_id: "im.vector.app",
        connector_token: "token123",
        device_id: "device123"
      }

      assert {:ok, created_app} = UnifiedPushAppService.create_unified_push_app(attrs)

      delete_attrs = %{
        connector_token: attrs.connector_token,
        device_id: attrs.device_id
      }

      assert {:ok, deleted_app} = UnifiedPushAppService.delete_unified_push_app(delete_attrs)
      assert deleted_app.id == created_app.id

      # Verify it's deleted
      assert {:error, :not_found} =
               UnifiedPushAppService.find_unified_push_app_by_id(created_app.id)
    end

    test "returns error when unified push app not found" do
      delete_attrs = %{
        connector_token: "nonexistent_token",
        device_id: "nonexistent_device"
      }

      assert {:error, :not_found} = UnifiedPushAppService.delete_unified_push_app(delete_attrs)
    end
  end
end
