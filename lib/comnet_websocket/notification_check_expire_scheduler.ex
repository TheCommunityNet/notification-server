defmodule ComnetWebsocket.NotificationCheckExpireScheduler do
  @moduledoc """
  GenServer that periodically checks for and marks expired notifications.

  This scheduler runs at regular intervals to update notifications that have
  passed their expiration time, marking them as expired.
  """

  use GenServer
  alias ComnetWebsocket.{Constants}
  alias ComnetWebsocket.Services.NotificationService

  @type state :: keyword()

  @doc """
  Starts the notification expire scheduler.

  ## Parameters
  - `opts` - Options for the GenServer

  ## Returns
  - `{:ok, pid}` - Scheduler started successfully
  - `{:error, reason}` - Scheduler failed to start
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    schedule_task()
    {:ok, opts}
  end

  @impl true
  def handle_info(:check_expire, state) do
    NotificationService.update_expired_notifications()
    schedule_task()
    {:noreply, state}
  end

  @spec schedule_task :: reference()
  defp schedule_task do
    Process.send_after(self(), :check_expire, Constants.expire_check_interval())
  end
end
