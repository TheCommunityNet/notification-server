defmodule ComnetWebsocketWeb.Admin.DeviceHTML do
  use ComnetWebsocketWeb, :html

  defp active_filters(%{device_id: device_id, user_id: user_id, ip_address: ip_address}) do
    []
    |> maybe_add_filter(device_id, :device_id, "Device ID")
    |> maybe_add_filter(user_id, :user_id, "User ID")
    |> maybe_add_filter(ip_address, :ip_address, "IP Address")
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

    if params == "", do: "/admin/devices", else: "/admin/devices?#{params}"
  end

  def index(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Header with filters --%>
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 px-6 py-4">
        <div class="flex flex-col sm:flex-row sm:items-start gap-4">
          <div class="flex-1">
            <h2 class="text-lg font-semibold text-gray-900">Devices</h2>
            <p class="text-sm text-gray-500 mt-0.5">
              All registered devices with their latest activity.
            </p>
          </div>

          <form action="/admin/devices" method="get" class="flex flex-wrap gap-2 items-end">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Device ID</label>
              <input
                type="search"
                name="device_id"
                value={@filters.device_id}
                placeholder="e.g. abc-123"
                class="px-3 py-2 text-sm border border-gray-300 rounded-lg bg-white
                       focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500
                       w-44 placeholder:text-gray-400"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">User ID</label>
              <input
                type="search"
                name="user_id"
                value={@filters.user_id}
                placeholder="e.g. user-456"
                class="px-3 py-2 text-sm border border-gray-300 rounded-lg bg-white
                       focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500
                       w-44 placeholder:text-gray-400"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">IP Address</label>
              <input
                type="search"
                name="ip_address"
                value={@filters.ip_address}
                placeholder="e.g. 192.168"
                class="px-3 py-2 text-sm border border-gray-300 rounded-lg bg-white
                       focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500
                       w-36 placeholder:text-gray-400"
              />
            </div>
            <button
              type="submit"
              class="px-4 py-2 text-sm font-medium text-white bg-indigo-600
                     hover:bg-indigo-700 rounded-lg transition-colors"
            >
              Filter
            </button>
            <%= if active_filters(@filters) != [] do %>
              <a
                href="/admin/devices"
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
            <a href="/admin/devices" class="text-xs text-gray-400 hover:text-gray-600 underline ml-1">
              Clear all filters
            </a>
          </div>
        <% end %>
      </div>

      <%!-- Results table --%>
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-gray-900">Results</h3>
          <span class="text-xs text-gray-400">{@filtered_count} devices</span>
        </div>

        <%= if @devices == [] do %>
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
                d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
              />
            </svg>
            <p class="text-sm text-gray-400">No devices match the current filters.</p>
            <%= if active_filters(@filters) != [] do %>
              <a
                href="/admin/devices"
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
                  <th class="px-6 py-3 text-left">Device ID</th>
                  <th class="px-6 py-3 text-left">User ID</th>
                  <th class="px-6 py-3 text-left">IP Address</th>
                  <th class="px-6 py-3 text-left">Last Active</th>
                  <th class="px-6 py-3 text-left">Latest Session</th>
                  <th class="px-6 py-3 text-left">Registered</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for device <- @devices do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-4">
                      <a
                        href={"/admin/devices?device_id=#{URI.encode_www_form(device.device_id)}"}
                        class={[
                          "font-mono text-xs hover:underline",
                          if(@filters.device_id == device.device_id,
                            do: "text-indigo-600 font-medium",
                            else: "text-gray-800 hover:text-indigo-600"
                          )
                        ]}
                        title={device.device_id}
                      >
                        {device.device_id}
                      </a>
                    </td>
                    <td class="px-6 py-4">
                      <%= if device.user_id do %>
                        <a
                          href={"/admin/devices?user_id=#{URI.encode_www_form(device.user_id)}"}
                          class={[
                            "font-mono text-xs hover:underline",
                            if(@filters.user_id == device.user_id,
                              do: "text-indigo-600 font-medium",
                              else: "text-gray-700 hover:text-indigo-600"
                            )
                          ]}
                          title={device.user_id}
                        >
                          {device.user_id}
                        </a>
                      <% else %>
                        <span class="text-gray-300 text-xs">—</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4">
                      <%= if device.ip_address do %>
                        <a
                          href={"/admin/devices?ip_address=#{URI.encode_www_form(device.ip_address)}"}
                          class={[
                            "hover:underline",
                            if(@filters.ip_address == device.ip_address,
                              do: "text-indigo-600 font-medium",
                              else: "text-gray-700 hover:text-indigo-600"
                            )
                          ]}
                        >
                          <.badge>{device.ip_address}</.badge>
                        </a>
                      <% else %>
                        <span class="text-gray-300 text-xs">—</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">
                      <%= if device.last_active_at do %>
                        {Calendar.strftime(device.last_active_at, "%Y-%m-%d %H:%M")}
                      <% else %>
                        <span class="text-gray-300">—</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 text-xs text-gray-500 whitespace-nowrap">
                      <%= if device.latest_started_at do %>
                        {Calendar.strftime(device.latest_started_at, "%Y-%m-%d %H:%M")}
                      <% else %>
                        <span class="text-gray-300">—</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4 text-xs text-gray-400 whitespace-nowrap">
                      {Calendar.strftime(device.inserted_at, "%Y-%m-%d %H:%M")}
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
