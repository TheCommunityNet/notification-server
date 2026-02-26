defmodule ComnetWebsocketWeb.Admin.NotificationHTML do
  use ComnetWebsocketWeb, :html

  def index(assigns) do
    ~H"""
    <div class="space-y-6">
      <.card title="Broadcast Notification to All Devices">
        <form action="/admin/notifications" method="post" class="space-y-4">
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <.input label="Title" name="notification[title]" required placeholder="Notification title" />
            <.input type="select" label="Category" name="notification[category]"
                    options={[{"Normal", "normal"}, {"Emergency (shows dialog)", "emergency"}]} />
          </div>
          <.input type="textarea" label="Content" name="notification[content]" required
                  placeholder="Notification message body..." rows={3} />
          <div class="flex flex-wrap items-end gap-4">
            <div class="w-40">
              <.input type="number" label="Expires in (hours)" name="notification[expired_in_hours]"
                      value="24" min="1" max="8760" />
            </div>
            <.button color="amber">Send to All Devices</.button>
          </div>
        </form>
      </.card>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-gray-900">All Notifications</h3>
          <span class="text-xs text-gray-400"><%= @total_count %> total</span>
        </div>

        <%= if @notifications == [] do %>
          <div class="px-6 py-12 text-center text-sm text-gray-400">
            No notifications sent yet.
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 text-xs text-gray-500 uppercase tracking-wide">
                <tr>
                  <th class="px-6 py-3 text-left">Title</th>
                  <th class="px-6 py-3 text-left">Content</th>
                  <th class="px-6 py-3 text-left">Category</th>
                  <th class="px-6 py-3 text-left">Type</th>
                  <th class="px-6 py-3 text-right">Devices received</th>
                  <th class="px-6 py-3 text-left">Status</th>
                  <th class="px-6 py-3 text-left">Expires</th>
                  <th class="px-6 py-3 text-left">Sent At</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for item <- @notifications do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-4 font-medium text-gray-900">
                      <%= get_in(item.notification.payload || %{}, ["title"]) || "—" %>
                    </td>
                    <td class="px-6 py-4 text-gray-500 max-w-50 truncate">
                      <%= get_in(item.notification.payload || %{}, ["content"]) || "—" %>
                    </td>
                    <td class="px-6 py-4">
                      <.badge color={if item.notification.category == "emergency", do: "red", else: "gray"}>
                        <%= item.notification.category || "—" %>
                      </.badge>
                    </td>
                    <td class="px-6 py-4">
                      <.badge color={if item.notification.type == "device", do: "blue", else: "purple"}>
                        <%= item.notification.type %>
                      </.badge>
                    </td>
                    <td class="px-6 py-4 text-gray-600 text-right">
                      <%= item.devices_received_count %>
                    </td>
                    <td class="px-6 py-4">
                      <.badge color={if item.notification.is_expired, do: "red", else: "green"}>
                        <%= if item.notification.is_expired, do: "Expired", else: "Active" %>
                      </.badge>
                    </td>
                    <td class="px-6 py-4 text-xs text-gray-400 min-w-40">
                      <%= Calendar.strftime(item.notification.expired_at, "%Y-%m-%d %H:%M") %>
                    </td>
                    <td class="px-6 py-4 text-xs text-gray-400 min-w-40">
                      <%= Calendar.strftime(item.notification.inserted_at, "%Y-%m-%d %H:%M") %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
          <.pagination page={@page} total_pages={@total_pages} base_path={@base_path}
                       total_count={@total_count} per_page={@per_page} />
        <% end %>
      </div>
    </div>
    """
  end
end
