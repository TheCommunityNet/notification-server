defmodule ComnetWebsocketWeb.AdminPagination do
  @moduledoc """
  Shared helpers for paginating admin list pages.
  Import this module in admin controllers that need pagination.
  """

  @doc """
  Parses the `page` query param, clamping to 1 if missing or invalid.
  """
  @spec parse_page(map()) :: pos_integer()
  def parse_page(params) do
    case Integer.parse(params["page"] || "1") do
      {n, _} when n >= 1 -> n
      _ -> 1
    end
  end

  @doc """
  Returns the total number of pages, always at least 1.
  """
  @spec total_pages(non_neg_integer(), pos_integer()) :: pos_integer()
  def total_pages(total_count, per_page) do
    max(1, ceil(total_count / per_page))
  end

  @doc """
  Builds the base path for pagination links by stripping the `page` param
  and re-encoding all remaining query parameters.

  ## Examples

      pagination_base_path("/admin/alerts", %{"search" => "foo", "page" => "2"})
      #=> "/admin/alerts?search=foo"

      pagination_base_path("/admin/users", %{})
      #=> "/admin/users"
  """
  @spec pagination_base_path(String.t(), map()) :: String.t()
  def pagination_base_path(base, params) do
    qs =
      params
      |> Map.drop(["page"])
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> URI.encode_query()

    if qs == "", do: base, else: "#{base}?#{qs}"
  end
end
