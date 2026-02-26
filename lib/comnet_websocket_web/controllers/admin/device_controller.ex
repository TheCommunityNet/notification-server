defmodule ComnetWebsocketWeb.Admin.DeviceController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  import ComnetWebsocketWeb.AdminPagination

  alias ComnetWebsocket.Services.DeviceService

  @per_page 25

  def index(conn, params) do
    page = parse_page(params)

    filters = %{
      device_id: params["device_id"],
      user_id: params["user_id"],
      ip_address: params["ip_address"]
    }

    devices =
      DeviceService.list_devices(Map.merge(filters, %{page: page, per_page: @per_page}))

    filtered_count = DeviceService.count_devices(filters)
    total_pages = total_pages(filtered_count, @per_page)
    base_path = pagination_base_path("/admin/devices", params)

    render(conn, :index,
      page_title: "Devices",
      devices: devices,
      filters: filters,
      filtered_count: filtered_count,
      page: page,
      total_pages: total_pages,
      per_page: @per_page,
      base_path: base_path
    )
  end
end
