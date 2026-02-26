defmodule ComnetWebsocketWeb.Admin.UserController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  import ComnetWebsocketWeb.AdminPagination

  alias ComnetWebsocket.Services.{UserService, ShellyService}

  @per_page 20

  def index(conn, params) do
    page = parse_page(params)
    users = UserService.list_users_with_shellies(page: page, per_page: @per_page)
    all_shellies = ShellyService.list_shellies()
    total_count = UserService.count_users()
    total_pages = total_pages(total_count, @per_page)
    base_path = pagination_base_path("/admin/users", params)

    render(conn, :index,
      page_title: "Users",
      users: users,
      all_shellies: all_shellies,
      total_count: total_count,
      page: page,
      total_pages: total_pages,
      per_page: @per_page,
      base_path: base_path
    )
  end

  def create(conn, %{"user" => user_params}) do
    case UserService.create_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: ~p"/admin/users")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to create user. Please check the inputs.")
        |> redirect(to: ~p"/admin/users")
    end
  end

  def generate_otp(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        case UserService.generate_otp_token(user) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "OTP token generated for #{user.name}.")
            |> redirect(to: ~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to generate OTP token.")
            |> redirect(to: ~p"/admin/users")
        end
    end
  end

  def regenerate_token(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        case UserService.regenerate_access_token(user) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Access token regenerated for #{user.name}.")
            |> redirect(to: ~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to regenerate access token.")
            |> redirect(to: ~p"/admin/users")
        end
    end
  end

  def edit(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        render(conn, :edit, page_title: "Edit User", user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        case UserService.update_user(user, user_params) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "User updated successfully.")
            |> redirect(to: ~p"/admin/users")

          {:error, changeset} ->
            render(conn, :edit, page_title: "Edit User", user: user, changeset: changeset)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        case UserService.delete_user(user) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "User \"#{user.name}\" deleted.")
            |> redirect(to: ~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to delete user.")
            |> redirect(to: ~p"/admin/users")
        end
    end
  end

  def assign_shelly(conn, %{"id" => user_id, "shelly_id" => shelly_id}) do
    case UserService.get_user(user_id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        case UserService.assign_shelly(user, shelly_id) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Shelly assigned to #{user.name}.")
            |> redirect(to: ~p"/admin/users")

          _ ->
            conn
            |> put_flash(:error, "Failed to assign shelly.")
            |> redirect(to: ~p"/admin/users")
        end
    end
  end

  def remove_shelly(conn, %{"id" => user_id, "shelly_id" => shelly_id}) do
    case UserService.get_user(user_id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        case UserService.remove_shelly(user, shelly_id) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Shelly removed from #{user.name}.")
            |> redirect(to: ~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to remove shelly.")
            |> redirect(to: ~p"/admin/users")
        end
    end
  end
end
