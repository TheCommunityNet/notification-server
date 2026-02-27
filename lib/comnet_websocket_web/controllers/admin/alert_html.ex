defmodule ComnetWebsocketWeb.Admin.AlertHTML do
  use ComnetWebsocketWeb, :html

  defp active_filters(%{shelly_id: shelly_id, user_id: user_id, search: search}) do
    []
    |> maybe_add_filter(shelly_id, :shelly_id, "Shelly")
    |> maybe_add_filter(user_id, :user_id, "User")
    |> maybe_add_filter(search, :search, "Search")
  end

  defp maybe_add_filter(acc, nil, _key, _label), do: acc
  defp maybe_add_filter(acc, "", _key, _label), do: acc

  defp maybe_add_filter(acc, value, key, label) do
    acc ++ [{key, label, value}]
  end

  defp remove_filter_url(filters, removed_key) do
    params =
      filters
      |> Map.drop([removed_key])
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(v)}" end)
      |> Enum.join("&")

    if params == "", do: "/admin/alerts", else: "/admin/alerts?#{params}"
  end

  def index(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Header with search --%>
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 px-6 py-4">
        <div class="flex flex-col sm:flex-row sm:items-center gap-4">
          <div class="flex-1">
            <h2 class="text-lg font-semibold text-gray-900">Alert History</h2>
            <p class="text-sm text-gray-500 mt-0.5">
              All shelly trigger events across the system.
            </p>
          </div>
          <form action="/admin/alerts" method="get" class="flex gap-2 items-center">
            <%!-- Preserve existing shelly_id / user_id filters when searching --%>
            <input :if={@filters.shelly_id} type="hidden" name="shelly_id" value={@filters.shelly_id} />
            <input :if={@filters.user_id} type="hidden" name="user_id" value={@filters.user_id} />
            <div class="relative">
              <svg
                class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <input
                type="search"
                name="search"
                value={@filters.search}
                placeholder="Search by user, device, shelly name or IP…"
                class="pl-9 pr-4 py-2 text-sm border border-gray-300 rounded-lg bg-white
                       focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500
                       w-72 placeholder:text-gray-400"
              />
            </div>
            <button
              type="submit"
              class="px-4 py-2 text-sm font-medium text-white bg-indigo-600
                           hover:bg-indigo-700 rounded-lg transition-colors"
            >
              Search
            </button>
            <%= if @filters.search && @filters.search != "" do %>
              <a
                href={remove_filter_url(@filters, :search)}
                class="px-3 py-2 text-sm text-gray-500 hover:text-gray-700 hover:bg-gray-100
                        rounded-lg transition-colors"
              >
                Clear
              </a>
            <% end %>
          </form>
        </div>

        <%!-- Active filter pills --%>
        <%= if active_filters(@filters) != [] do %>
          <div class="mt-3 flex flex-wrap gap-2 items-center">
            <span class="text-xs text-gray-500">Filtering by:</span>
            <%= for {key, label, value} <- active_filters(@filters) do %>
              <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs
                           font-medium bg-indigo-50 text-indigo-700 border border-indigo-200">
                <span class="font-semibold">{label}:</span>
                <span class="font-mono max-w-40 truncate" title={value}>{value}</span>
                <a
                  href={remove_filter_url(@filters, key)}
                  class="ml-0.5 text-indigo-400 hover:text-indigo-600 font-bold leading-none"
                  title={"Remove #{label} filter"}
                >
                  ×
                </a>
              </span>
            <% end %>
            <a
              href="/admin/alerts"
              class="text-xs text-gray-400 hover:text-gray-600 underline ml-1"
            >
              Clear all filters
            </a>
          </div>
        <% end %>
      </div>

      <%!-- Results table --%>
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-gray-900">Results</h3>
          <span class="text-xs text-gray-400">{@filtered_count} records</span>
        </div>

        <%= if @alerts == [] do %>
          <div class="px-6 py-16 text-center">
            <svg
              class="w-8 h-8 text-gray-300 mx-auto mb-3"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z"
              />
            </svg>
            <p class="text-sm text-gray-400">No alerts match the current filters.</p>
            <%= if active_filters(@filters) != [] or (@filters.search && @filters.search != "") do %>
              <a
                href="/admin/alerts"
                class="text-sm text-indigo-500 hover:underline mt-2 inline-block"
              >
                Clear all filters
              </a>
            <% end %>
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 text-xs text-gray-500 uppercase tracking-wide">
                <tr>
                  <th class="px-6 py-3 text-left">Triggered At</th>
                  <th class="px-6 py-3 text-left">User</th>
                  <th class="px-6 py-3 text-left">Device ID</th>
                  <th class="px-6 py-3 text-left">Shelly</th>
                  <th class="px-6 py-3 text-left">Shelly IP</th>
                  <th class="px-6 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for alert <- @alerts do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">
                      {Calendar.strftime(alert.triggered_at, "%Y-%m-%d %H:%M:%S")}
                    </td>
                    <td class="px-6 py-4">
                      <a
                        href={"/admin/alerts?user_id=#{alert.user_id}"}
                        class={[
                          "font-medium hover:underline",
                          if(@filters.user_id == to_string(alert.user_id),
                            do: "text-indigo-600",
                            else: "text-gray-900 hover:text-indigo-600"
                          )
                        ]}
                      >
                        {alert.user_name}
                      </a>
                    </td>
                    <td class="px-6 py-4 font-mono text-xs text-gray-500">
                      {alert.device_id || "—"}
                    </td>
                    <td class="px-6 py-4">
                      <a
                        href={"/admin/alerts?shelly_id=#{alert.shelly_id}"}
                        class={[
                          "hover:underline",
                          if(@filters.shelly_id == to_string(alert.shelly_id),
                            do: "text-indigo-600 font-medium",
                            else: "text-gray-700 hover:text-indigo-600"
                          )
                        ]}
                      >
                        {alert.shelly_name}
                      </a>
                    </td>
                    <td class="px-6 py-4">
                      <.badge>{alert.shelly_ip}</.badge>
                    </td>
                    <td class="px-6 py-4 text-right">
                      <div class="flex justify-end gap-2">
                        <a
                          href={"/admin/alerts?user_id=#{alert.user_id}"}
                          class="text-gray-400 hover:text-indigo-600 transition-colors"
                          title="Filter by this user"
                        >
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                            />
                          </svg>
                        </a>
                        <a
                          href={"/admin/alerts?shelly_id=#{alert.shelly_id}"}
                          class="text-gray-400 hover:text-emerald-600 transition-colors"
                          title="Filter by this shelly"
                        >
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18"
                            />
                          </svg>
                        </a>
                        <a
                          href={"/admin/alerts?user_id=#{alert.user_id}&shelly_id=#{alert.shelly_id}"}
                          class="text-gray-400 hover:text-amber-600 transition-colors"
                          title="Filter by this user + shelly combination"
                        >
                          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2a1 1 0 01-.293.707L13 13.414V19a1 1 0 01-.553.894l-4 2A1 1 0 017 21v-7.586L3.293 6.707A1 1 0 013 6V4z"
                            />
                          </svg>
                        </a>
                      </div>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            base_path={@base_path}
            total_count={@filtered_count}
            per_page={@per_page}
          />
        <% end %>
      </div>
    </div>
    """
  end
end
