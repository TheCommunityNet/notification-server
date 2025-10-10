defmodule ComnetWebsocket.Utils.TimeUtils do
  @spec format_uptime(integer()) :: String.t()
  def format_uptime(uptime) do
    days = div(uptime, 86400)
    hours = div(rem(uptime, 86400), 3600)
    minutes = div(rem(uptime, 3600), 60)
    seconds = rem(uptime, 60)

    str = ""

    if days > 0, do: str <> "#{days}d", else: str
    if hours > 0, do: str <> "#{hours}h", else: str
    if minutes > 0, do: str <> "#{minutes}m", else: str
    if seconds > 0, do: str <> "#{seconds}s", else: str

    str
  end
end
