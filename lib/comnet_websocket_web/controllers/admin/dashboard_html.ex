defmodule ComnetWebsocketWeb.Admin.DashboardHTML do
  use ComnetWebsocketWeb, :html

  def index(assigns) do
    ~H"""
    <div class="space-y-8">
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
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
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-3 gap-6">
        <a href="/admin/users"
           class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:border-indigo-300 hover:shadow-md transition-all group">
          <h3 class="font-semibold text-gray-900 group-hover:text-indigo-600">Manage Users</h3>
          <p class="text-sm text-gray-500 mt-1">Create users, generate OTP tokens, regenerate access tokens.</p>
        </a>
        <a href="/admin/shellies"
           class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:border-emerald-300 hover:shadow-md transition-all group">
          <h3 class="font-semibold text-gray-900 group-hover:text-emerald-600">Manage Shellies</h3>
          <p class="text-sm text-gray-500 mt-1">Register and manage Shelly IoT devices with IP addresses.</p>
        </a>
        <a href="/admin/notifications"
           class="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:border-amber-300 hover:shadow-md transition-all group">
          <h3 class="font-semibold text-gray-900 group-hover:text-amber-600">Send Notifications</h3>
          <p class="text-sm text-gray-500 mt-1">Broadcast notifications to all connected devices.</p>
        </a>
      </div>
    </div>
    """
  end
end
