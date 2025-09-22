defmodule ComnetWebsocket.ChannelWatcher do
  @moduledoc """
  A GenServer that monitors WebSocket channels and restarts them when they crash.

  This module provides a supervision mechanism for WebSocket channels by monitoring
  their lifecycle and automatically restarting them when they exit unexpectedly.
  """

  use GenServer

  @type channel_state :: %{channels: %{pid() => mfa_tuple()}}
  @type mfa_tuple :: {module(), atom(), [any()]}

  ## Client API

  @doc """
  Starts monitoring a channel process.

  When the monitored process exits, it will be automatically restarted using
  the provided MFA (Module, Function, Arguments) tuple.

  ## Parameters
  - `server_name` - The name of the ChannelWatcher GenServer
  - `pid` - The PID of the process to monitor
  - `mfa` - A tuple of {Module, Function, Arguments} to restart the process

  ## Returns
  - `:ok` - The process is now being monitored
  """
  @spec monitor(GenServer.server(), pid(), mfa_tuple()) :: :ok
  def monitor(server_name, pid, mfa) do
    GenServer.call(server_name, {:monitor, pid, mfa})
  end

  @doc """
  Stops monitoring a channel process.

  ## Parameters
  - `server_name` - The name of the ChannelWatcher GenServer
  - `pid` - The PID of the process to stop monitoring

  ## Returns
  - `:ok` - The process is no longer being monitored
  """
  @spec demonitor(GenServer.server(), pid()) :: :ok
  def demonitor(server_name, pid) do
    GenServer.call(server_name, {:demonitor, pid})
  end

  ## Server API

  @doc """
  Starts the ChannelWatcher GenServer.

  ## Parameters
  - `name` - The name to register the GenServer under

  ## Returns
  - `{:ok, pid}` - The GenServer started successfully
  - `{:error, reason}` - The GenServer failed to start
  """
  @spec start_link(atom()) :: GenServer.on_start()
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{channels: Map.new()}}
  end

  @impl true
  def handle_call({:monitor, pid, mfa}, _from, state) do
    Process.link(pid)
    {:reply, :ok, put_channel(state, pid, mfa)}
  end

  @impl true
  def handle_call({:demonitor, pid}, _from, state) do
    case Map.fetch(state.channels, pid) do
      :error ->
        {:reply, :ok, state}

      {:ok, _mfa} ->
        Process.unlink(pid)
        {:reply, :ok, drop_channel(state, pid)}
    end
  end

  @impl true
  def handle_info({:EXIT, pid, _reason}, state) do
    case Map.fetch(state.channels, pid) do
      :error ->
        {:noreply, state}

      {:ok, {mod, func, args}} ->
        Task.start_link(fn -> apply(mod, func, args) end)
        {:noreply, drop_channel(state, pid)}
    end
  end

  @spec drop_channel(channel_state(), pid()) :: channel_state()
  defp drop_channel(state, pid) do
    %{state | channels: Map.delete(state.channels, pid)}
  end

  @spec put_channel(channel_state(), pid(), mfa_tuple()) :: channel_state()
  defp put_channel(state, pid, mfa) do
    %{state | channels: Map.put(state.channels, pid, mfa)}
  end
end
