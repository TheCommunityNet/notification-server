defmodule ComnetWebsocketWeb.Admin.ShellyHTML do
  use ComnetWebsocketWeb, :html

  def edit(assigns) do
    ~H"""
    <div class="max-w-lg">
      <div class="mb-6">
        <a href="/admin/shellies" class="text-sm text-indigo-600 hover:underline">← Back to Shellies</a>
      </div>
      <.card title={"Edit Shelly: #{@shelly.name}"}>
        <form action={"/admin/shellies/#{@shelly.id}"} method="post" class="space-y-4">
          <input type="hidden" name="_method" value="patch" />
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          <.input label="Name" name="shelly[name]" required value={@shelly.name} />
          <.input label="IP Address" name="shelly[ip_address]" required value={@shelly.ip_address}
                  placeholder="e.g. 192.168.1.100" />
          <div class="flex gap-3 pt-2">
            <.button color="emerald">Save Changes</.button>
            <a href="/admin/shellies"
               class="inline-flex items-center px-5 py-2 text-sm font-medium text-gray-600
                      bg-gray-100 hover:bg-gray-200 rounded-lg transition-colors">
              Cancel
            </a>
          </div>
        </form>
      </.card>
    </div>
    """
  end

  def index(assigns) do
    ~H"""
    <div class="space-y-6">
      <.card title="Register New Shelly">
        <form action="/admin/shellies" method="post" class="flex flex-wrap gap-4 items-end">
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          <div class="flex-1 min-w-48">
            <.input label="Name" name="shelly[name]" required placeholder="e.g. Living Room Switch" />
          </div>
          <div class="flex-1 min-w-48">
            <.input label="IP Address" name="shelly[ip_address]" required placeholder="e.g. 192.168.1.100" />
          </div>
          <.button color="emerald">Register Shelly</.button>
        </form>
      </.card>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-gray-900">Registered Shellies</h3>
          <span class="text-xs text-gray-400"><%= length(@shellies) %> total</span>
        </div>

        <%= if @shellies == [] do %>
          <div class="px-6 py-12 text-center text-sm text-gray-400">
            No shellies registered yet. Add one above.
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 text-xs text-gray-500 uppercase tracking-wide">
                <tr>
                  <th class="px-6 py-3 text-left">Name</th>
                  <th class="px-6 py-3 text-left">IP Address</th>
                  <th class="px-6 py-3 text-left">Registered</th>
                  <th class="px-6 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for shelly <- @shellies do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-4 font-medium text-gray-900"><%= shelly.name %></td>
                    <td class="px-6 py-4">
                      <.badge><%= shelly.ip_address %></.badge>
                    </td>
                    <td class="px-6 py-4 text-xs text-gray-400">
                      <%= Calendar.strftime(shelly.inserted_at, "%Y-%m-%d %H:%M") %>
                    </td>
                    <td class="px-6 py-4 text-right">
                      <.dropdown id={"shelly-actions-#{shelly.id}"}>
                        <.dropdown_item href={"/admin/shellies/#{shelly.id}/edit"}>
                          Edit
                        </.dropdown_item>
                        <.dropdown_divider />
                        <form action={"/admin/shellies/#{shelly.id}"} method="post">
                          <input type="hidden" name="_method" value="delete" />
                          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                          <.dropdown_item danger onclick="return confirm('Delete this shelly?')">
                            Delete
                          </.dropdown_item>
                        </form>
                      </.dropdown>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
