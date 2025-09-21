defmodule ComnetWebsocket.NotificationCheckExpireScheduler do
  use GenServer

  @interval 600_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def handle_info(:check_expire, state) do
    ComnetWebsocket.EctoService.update_expired_notifications()
    schedule_task()
    {:noreply, state}
  end

  def init(opts) do
    schedule_task()
    {:ok, opts}
  end

  defp schedule_task do
    Process.send_after(self(), :check_expire, @interval)
  end
end
