defmodule ComnetWebsocketWeb.Admin.UserHTML do
  use ComnetWebsocketWeb, :html

  embed_templates "user_html/*"

  defp unassigned_shellies(user, all_shellies) do
    assigned_ids = MapSet.new(user.shellies, & &1.id)
    Enum.reject(all_shellies, &MapSet.member?(assigned_ids, &1.id))
  end
end
