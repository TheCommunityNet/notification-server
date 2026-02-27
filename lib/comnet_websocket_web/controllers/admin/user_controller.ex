defmodule ComnetWebsocketWeb.Admin.UserController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  import ComnetWebsocketWeb.AdminPagination

  alias ComnetWebsocket.Services.{UserService, ShellyService}

  @per_page 20

  def index(conn, params) do
    filters = Map.take(params, ["search", "shelly_id"])
    page = parse_page(params)

    users =
      UserService.list_users_with_shellies(page: page, per_page: @per_page, filters: filters)

    all_shellies = ShellyService.list_shellies()
    total_count = UserService.count_users(filters)
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
      base_path: base_path,
      filters: filters
    )
  end

  def create(conn, _params) do
    all_shellies = ShellyService.list_shellies()
    render(conn, :create, page_title: "Create User", all_shellies: all_shellies)
  end

  def store(conn, %{"user" => user_params}) do
    shelly_ids = Map.get(user_params, "shelly_ids", [])

    case UserService.create_user(user_params) do
      {:ok, user} ->
        Enum.each(shelly_ids, &UserService.assign_shelly(user, &1))

        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: ~p"/admin/users")

      {:error, _changeset} ->
        all_shellies = ShellyService.list_shellies()

        conn
        |> put_flash(:error, "Failed to create user. Please check the inputs.")
        |> render(:new, page_title: "Create User", all_shellies: all_shellies)
    end
  end

  def generate_otp(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect_back(~p"/admin/users")

      user ->
        case UserService.generate_otp_token(user) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "OTP token generated for #{user.name}.")
            |> redirect_back(~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to generate OTP token.")
            |> redirect_back(~p"/admin/users")
        end
    end
  end

  def regenerate_token(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect_back(~p"/admin/users")

      user ->
        case UserService.regenerate_access_token(user) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Access token regenerated for #{user.name}.")
            |> redirect_back(~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to regenerate access token.")
            |> redirect_back(~p"/admin/users")
        end
    end
  end

  def clear_otp(conn, %{"id" => id}) do
    case UserService.get_user(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect_back(~p"/admin/users")

      user ->
        case UserService.clear_otp_token(user) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "OTP token cleared for #{user.name}.")
            |> redirect_back(~p"/admin/users")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to clear OTP token.")
            |> redirect_back(~p"/admin/users")
        end
    end
  end

  def edit(conn, %{"id" => id}) do
    case UserService.get_user_with_shellies(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        all_shellies = ShellyService.list_shellies()
        render(conn, :edit, page_title: "Edit User", user: user, all_shellies: all_shellies)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    case UserService.get_user_with_shellies(id) do
      nil ->
        conn |> put_flash(:error, "User not found.") |> redirect(to: ~p"/admin/users")

      user ->
        shelly_ids = Map.get(user_params, "shelly_ids", []) |> List.wrap()
        params_without_shellies = Map.delete(user_params, "shelly_ids")

        case UserService.update_user(user, params_without_shellies) do
          {:ok, updated_user} ->
            case UserService.set_user_shellies(updated_user, shelly_ids) do
              {:ok, _} ->
                conn
                |> put_flash(:info, "User updated successfully.")
                |> redirect(to: ~p"/admin/users/#{id}/edit")

              {:error, _} ->
                all_shellies = ShellyService.list_shellies()

                conn
                |> put_flash(:error, "Failed to update shelly assignments.")
                |> render(:edit,
                  page_title: "Edit User",
                  user: updated_user,
                  all_shellies: all_shellies
                )
            end

          {:error, _changeset} ->
            all_shellies = ShellyService.list_shellies()

            conn
            |> put_flash(:error, "Failed to update user.")
            |> render(:edit, page_title: "Edit User", user: user, all_shellies: all_shellies)
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
            |> redirect(to: ~p"/admin/users/#{user_id}/edit")

          _ ->
            conn
            |> put_flash(:error, "Failed to assign shelly.")
            |> redirect(to: ~p"/admin/users/#{user_id}/edit")
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
            |> redirect(to: ~p"/admin/users/#{user_id}/edit")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to remove shelly.")
            |> redirect(to: ~p"/admin/users/#{user_id}/edit")
        end
    end
  end

  defp redirect_back(conn, fallback) do
    referer = get_req_header(conn, "referer") |> List.first()

    with referer when is_binary(referer) <- referer,
         %URI{host: host, path: path} <- URI.parse(referer),
         true <- is_nil(host) or host == conn.host,
         true <- is_binary(path) and byte_size(path) > 0 do
      redirect(conn, to: path)
    else
      _ -> redirect(conn, to: fallback)
    end
  end
end
