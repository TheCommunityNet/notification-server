defmodule ComnetWebsocket.Utils.TimeUtils do
  @spec format_uptime(integer()) :: String.t()
  def format_uptime(uptime) do
    days = div(uptime, 86400)
    hours = div(rem(uptime, 86400), 3600)
    minutes = div(rem(uptime, 3600), 60)
    seconds = rem(uptime, 60)

    parts = []
    parts = if days > 0, do: parts ++ ["#{days}d"], else: parts
    parts = if hours > 0, do: parts ++ ["#{hours}h"], else: parts
    parts = if minutes > 0, do: parts ++ ["#{minutes}m"], else: parts
    parts = if seconds > 0, do: parts ++ ["#{seconds}s"], else: parts

    Enum.join(parts, "")
  end
end
