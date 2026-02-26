defmodule ComnetWebsocket.Services.UserServiceTest do
  use ComnetWebsocket.DataCase, async: true

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.User
  alias ComnetWebsocket.Services.UserService

  describe "generate_otp_token/1" do
    test "sets a unique otp_token on the user" do
      {:ok, user} =
        %User{}
        |> User.admin_create_changeset(%{name: "OTP Test User"})
        |> Repo.insert()

      assert user.otp_token == nil

      assert {:ok, updated} = UserService.generate_otp_token(user)
      assert updated.otp_token != nil
      assert updated.otp_token != user.otp_token
      assert String.length(updated.otp_token) == 16
      assert updated.otp_token =~ ~r/\A[0-9a-f]+\z/
    end

    test "generates different tokens for different users" do
      {:ok, user1} =
        %User{}
        |> User.admin_create_changeset(%{name: "User One"})
        |> Repo.insert()

      {:ok, user2} =
        %User{}
        |> User.admin_create_changeset(%{name: "User Two"})
        |> Repo.insert()

      {:ok, u1} = UserService.generate_otp_token(user1)
      {:ok, u2} = UserService.generate_otp_token(user2)

      assert u1.otp_token != nil
      assert u2.otp_token != nil
      assert u1.otp_token != u2.otp_token
    end

    test "regenerating otp_token replaces the previous token" do
      {:ok, user} =
        %User{}
        |> User.admin_create_changeset(%{name: "Regen User"})
        |> Repo.insert()

      {:ok, u1} = UserService.generate_otp_token(user)
      first_token = u1.otp_token
      {:ok, u2} = UserService.generate_otp_token(u1)
      second_token = u2.otp_token

      assert first_token != nil
      assert second_token != nil
      assert first_token != second_token
    end
  end
end
