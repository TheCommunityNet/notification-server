defmodule ComnetWebsocketWeb.Admin.ShellyController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  alias ComnetWebsocket.Services.ShellyService

  def index(conn, _params) do
    shellies = ShellyService.list_shellies()
    render(conn, :index, page_title: "Shellies", shellies: shellies)
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
        |> redirect(to: ~p"/admin/shellies")
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
