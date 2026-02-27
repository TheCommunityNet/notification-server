defmodule ComnetWebsocketWeb.Admin.ShellyController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  import ComnetWebsocketWeb.AdminPagination

  alias ComnetWebsocket.Services.ShellyService

  @per_page 25

  def index(conn, params) do
    filters = Map.take(params, ["search"])
    page = parse_page(params)

    shellies =
      ShellyService.list_shellies(
        page: page,
        per_page: @per_page,
        filters: filters
      )

    total_count = ShellyService.count_shellies(filters: filters)
    total_pages = total_pages(total_count, @per_page)
    base_path = pagination_base_path("/admin/shellies", params)

    render(conn, :index,
      page_title: "Shellies",
      shellies: shellies,
      total_count: total_count,
      page: page,
      total_pages: total_pages,
      per_page: @per_page,
      base_path: base_path,
      filters: filters
    )
  end

  def new(conn, _params) do
    render(conn, :create, page_title: "Register Shelly")
  end

  def create(conn, %{"shelly" => shelly_params}) do
    case ShellyService.create_shelly(shelly_params) do
      {:ok, _shelly} ->
        conn
        |> put_flash(:info, "Shelly registered successfully.")
        |> redirect(to: ~p"/admin/shellies")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to register shelly. Please check the inputs.")
        |> redirect(to: ~p"/admin/shellies/create")
    end
  end

  def edit(conn, %{"id" => id}) do
    case ShellyService.get_shelly(id) do
      nil ->
        conn |> put_flash(:error, "Shelly not found.") |> redirect(to: ~p"/admin/shellies")

      shelly ->
        render(conn, :edit, page_title: "Edit Shelly", shelly: shelly)
    end
  end

  def update(conn, %{"id" => id, "shelly" => shelly_params}) do
    case ShellyService.get_shelly(id) do
      nil ->
        conn |> put_flash(:error, "Shelly not found.") |> redirect(to: ~p"/admin/shellies")

      shelly ->
        case ShellyService.update_shelly(shelly, shelly_params) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Shelly updated successfully.")
            |> redirect(to: ~p"/admin/shellies")

          {:error, changeset} ->
            render(conn, :edit, page_title: "Edit Shelly", shelly: shelly, changeset: changeset)
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case ShellyService.get_shelly(id) do
      nil ->
        conn |> put_flash(:error, "Shelly not found.") |> redirect(to: ~p"/admin/shellies")

      shelly ->
        case ShellyService.delete_shelly(shelly) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Shelly \"#{shelly.name}\" deleted.")
            |> redirect(to: ~p"/admin/shellies")

          {:error, _} ->
            conn
            |> put_flash(:error, "Failed to delete shelly.")
            |> redirect(to: ~p"/admin/shellies")
        end
    end
  end
end
