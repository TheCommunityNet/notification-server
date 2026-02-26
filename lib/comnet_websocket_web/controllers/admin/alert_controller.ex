defmodule ComnetWebsocketWeb.Admin.AlertController do
  use ComnetWebsocketWeb, :controller

  plug :put_layout, html: {ComnetWebsocketWeb.Layouts, :app}

  import ComnetWebsocketWeb.AdminPagination

  alias ComnetWebsocket.Services.AlertService

  @per_page 50

  def index(conn, params) do
    page = parse_page(params)

    filters = %{
      search: params["search"],
      shelly_id: params["shelly_id"],
      user_id: params["user_id"]
    }

    alerts = AlertService.list_alerts(Map.merge(filters, %{page: page, per_page: @per_page}))
    filtered_count = AlertService.count_alerts(filters)
    total_pages = total_pages(filtered_count, @per_page)
    base_path = pagination_base_path("/admin/alerts", params)

    render(conn, :index,
      page_title: "Alert History",
      alerts: alerts,
      filters: filters,
      filtered_count: filtered_count,
      page: page,
      total_pages: total_pages,
      per_page: @per_page,
      base_path: base_path
    )
  end
end
