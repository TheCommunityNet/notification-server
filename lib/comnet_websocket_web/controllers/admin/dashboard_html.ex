defmodule ComnetWebsocketWeb.Admin.DashboardHTML do
  use ComnetWebsocketWeb, :html

  def index(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <.stat_card label="Total Users" value={@user_count} href="/admin/users"
                    link_label="Manage users" color="indigo">
          <:icon>
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          </:icon>
        </.stat_card>

        <.stat_card label="Registered Shellies" value={@shelly_count} href="/admin/shellies"
                    link_label="Manage shellies" color="emerald">
          <:icon>
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18" />
            </svg>
          </:icon>
        </.stat_card>

        <.stat_card label="Total Notifications" value={@notification_count}
                    href="/admin/notifications" link_label="View notifications" color="amber">
          <:icon>
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                    d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </:icon>
        </.stat_card>

        <.stat_card label="Shelly Alert Triggers" value={@alert_count}
                    href="/admin/alerts" link_label="View alert history" color="red">
          <:icon>
            <svg class="w-4 h-4 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </:icon>
        </.stat_card>

        <.stat_card label="Live WS Connections" value={@ws_connection_count}
                    link_label="Authenticated users online" color="teal">
          <:icon>
            <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                d="M8.111 16.404a5.5 5.5 0 017.778 0M12 20h.01m-7.08-7.071c3.904-3.905 10.236-3.905 14.141 0M1.394 9.393c5.857-5.857 15.355-5.857 21.213 0" />
            </svg>
          </:icon>
        </.stat_card>
      </div>
    </div>
    """
  end
end
