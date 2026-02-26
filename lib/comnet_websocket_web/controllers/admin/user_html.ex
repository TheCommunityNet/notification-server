defmodule ComnetWebsocketWeb.Admin.UserHTML do
  use ComnetWebsocketWeb, :html

  def edit(assigns) do
    ~H"""
    <div class="max-w-lg">
      <div class="mb-6">
        <a href="/admin/users" class="text-sm text-indigo-600 hover:underline">← Back to Users</a>
      </div>
      <.card title={"Edit User: #{@user.name}"}>
        <form action={"/admin/users/#{@user.id}"} method="post" class="space-y-4">
          <input type="hidden" name="_method" value="patch" />
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          <.input label="Name" name="user[name]" required value={@user.name} />
          <div class="flex gap-3 pt-2">
            <.button>Save Changes</.button>
            <a href="/admin/users"
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

  defp unassigned_shellies(user, all_shellies) do
    assigned_ids = MapSet.new(user.shellies, & &1.id)
    Enum.reject(all_shellies, &MapSet.member?(assigned_ids, &1.id))
  end

  def index(assigns) do
    ~H"""
    <div class="space-y-6">
      <.card title="Create New User">
        <form action="/admin/users" method="post" class="flex flex-wrap gap-4 items-end">
          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
          <div class="flex-1 min-w-48">
            <.input label="Name" name="user[name]" required placeholder="e.g. John Doe" />
          </div>
          <.button>Create User</.button>
        </form>
      </.card>

      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
          <h3 class="text-base font-semibold text-gray-900">All Users</h3>
          <span class="text-xs text-gray-400"><%= @total_count %> total</span>
        </div>

        <%= if @users == [] do %>
          <div class="px-6 py-12 text-center text-sm text-gray-400">
            No users yet. Create one above.
          </div>
        <% else %>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-gray-50 text-xs text-gray-500 uppercase tracking-wide">
                <tr>
                  <th class="px-6 py-3 text-left">Name</th>
                  <th class="px-6 py-3 text-left">Device ID</th>
                  <th class="px-6 py-3 text-left">OTP Token</th>
                  <th class="px-6 py-3 text-left">Access Token</th>
                  <th class="px-6 py-3 text-left">Shellies</th>
                  <th class="px-6 py-3 text-left">Created</th>
                  <th class="px-6 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <%= for user <- @users do %>
                  <tr class="hover:bg-gray-50 transition-colors align-top">
                    <td class="px-6 py-4 font-medium text-gray-900"><%= user.name %></td>
                    <td class="px-6 py-4 font-mono text-xs text-gray-500">
                      <%= user.device_id || "—" %>
                    </td>
                    <td class="px-6 py-4">
                      <%= if user.otp_token do %>
                        <.badge color="indigo"><%= user.otp_token %></.badge>
                      <% else %>
                        <span class="text-gray-400 text-xs">not generated</span>
                      <% end %>
                    </td>
                    <td class="px-6 py-4">
                      <span class="font-mono text-xs bg-gray-100 text-gray-700 px-2 py-1 rounded
                                   max-w-36 inline-block truncate align-middle"
                            title={user.access_token}>
                        <%= user.access_token %>
                      </span>
                    </td>

                    <%!-- Shellies cell --%>
                    <td class="px-6 py-4">
                      <div class="space-y-2 min-w-44">
                        <%!-- Assigned shellies with remove button --%>
                        <div :if={user.shellies != []} class="flex flex-wrap gap-1">
                          <%= for shelly <- user.shellies do %>
                            <form action={"/admin/users/#{user.id}/shellies/#{shelly.id}"}
                                  method="post" class="inline">
                              <input type="hidden" name="_method" value="delete" />
                              <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                              <button type="submit"
                                      title="Click to remove"
                                      class="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs
                                             bg-emerald-50 text-emerald-700
                                             hover:bg-red-50 hover:text-red-700 transition-colors group">
                                <%= shelly.name %>
                                <span class="opacity-40 group-hover:opacity-100 font-bold">×</span>
                              </button>
                            </form>
                          <% end %>
                        </div>
                        <%!-- Assign new shelly dropdown --%>
                        <form :if={unassigned_shellies(user, @all_shellies) != []}
                              action={"/admin/users/#{user.id}/shellies"} method="post"
                              class="flex gap-1 items-center">
                          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                          <select name="shelly_id"
                                  class="flex-1 px-2 py-1 text-xs border border-gray-300 rounded-lg
                                         bg-white focus:outline-none focus:ring-1 focus:ring-indigo-500">
                            <option :for={s <- unassigned_shellies(user, @all_shellies)}
                                    value={s.id}>
                              <%= s.name %>
                            </option>
                          </select>
                          <.button color="ghost" size="sm" type="submit">+ Assign</.button>
                        </form>
                        <span :if={unassigned_shellies(user, @all_shellies) == [] and user.shellies == []}
                              class="text-xs text-gray-400">
                          No shellies registered
                        </span>
                      </div>
                    </td>

                    <td class="px-6 py-4 text-xs text-gray-400">
                      <%= Calendar.strftime(user.inserted_at, "%Y-%m-%d %H:%M") %>
                    </td>
                    <td class="px-6 py-4 text-right">
                      <.dropdown id={"user-actions-#{user.id}"}>
                        <.dropdown_item href={"/admin/users/#{user.id}/edit"}>Edit</.dropdown_item>
                        <.dropdown_item href={"/admin/alerts?user_id=#{user.id}"}>
                          View Alert History
                        </.dropdown_item>
                        <.dropdown_divider />
                        <form action={"/admin/users/#{user.id}/generate_otp"} method="post">
                          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                          <.dropdown_item>Generate OTP Token</.dropdown_item>
                        </form>
                        <form action={"/admin/users/#{user.id}/regenerate_token"} method="post">
                          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                          <.dropdown_item>Regenerate Access Token</.dropdown_item>
                        </form>
                        <.dropdown_divider />
                        <form action={"/admin/users/#{user.id}"} method="post">
                          <input type="hidden" name="_method" value="delete" />
                          <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                          <.dropdown_item danger onclick={"return confirm('Delete user #{user.name}?')"}>
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
          <.pagination page={@page} total_pages={@total_pages} base_path={@base_path}
                       total_count={@total_count} per_page={@per_page} />
        <% end %>
      </div>
    </div>
    """
  end
end
