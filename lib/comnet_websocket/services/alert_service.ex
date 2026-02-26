defmodule ComnetWebsocket.Services.AlertService do
  @moduledoc """
  Service for shelly alert operations.

  Handles listing a user's assigned shellies and triggering alerts on them.
  Each trigger is recorded in the `shelly_alerts` table.
  """

  import Ecto.Query

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{Shelly, ShellyAlert, User}

  @doc """
  Returns the list of shellies assigned to a user, with only `id` and `name`.
  """
  @spec list_user_shellies(User.t()) :: [map()]
  def list_user_shellies(%User{id: user_id}) do
    from(s in Shelly,
      join: us in "user_shellies",
      on: us.shelly_id == s.id,
      where: us.user_id == type(^user_id, UUIDv7),
      select: %{id: s.id, name: s.name},
      order_by: [asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  Toggles a specific shelly for the given user.

  If a dispatch task is already running for the shelly, it is stopped and the
  relay is turned off immediately. Otherwise a new alert is recorded and the
  3-cycle dispatch task is started.

  Returns `{:ok, :stopped}`, `{:ok, ShellyAlert.t()}`, `{:error, :forbidden}`,
  or `{:error, :not_found}`.
  """
  @spec toggle_shelly(User.t(), String.t()) ::
          {:ok, :stopped | ShellyAlert.t()}
          | {:error, :forbidden | :not_found | Ecto.Changeset.t()}
  def toggle_shelly(%User{id: user_id} = _user, shelly_id) do
    shelly =
      from(s in Shelly,
        join: us in "user_shellies",
        on: us.shelly_id == s.id,
        where: s.id == ^shelly_id and us.user_id == type(^user_id, UUIDv7)
      )
      |> Repo.one()

    case shelly do
      nil ->
        case Repo.get(Shelly, shelly_id) do
          nil -> {:error, :not_found}
          _shelly -> {:error, :forbidden}
        end

      shelly ->
        if task_running?(shelly.id) do
          stop_shelly_task(shelly.id)
          {:ok, :stopped}
        else
          result = record_alert(shelly.id, user_id)
          if match?({:ok, _}, result), do: dispatch_to_shelly(shelly)
          result
        end
    end
  end

  @doc """
  Toggles all shellies assigned to the user.

  Each shelly is independently toggled: stopped if already running, started otherwise.
  Returns a list of per-shelly results.
  """
  @spec toggle_all_shellies(User.t()) :: [map()]
  def toggle_all_shellies(%User{id: user_id} = _user) do
    shellies =
      from(s in Shelly,
        join: us in "user_shellies",
        on: us.shelly_id == s.id,
        where: us.user_id == type(^user_id, UUIDv7)
      )
      |> Repo.all()

    Enum.map(shellies, fn shelly ->
      result =
        if task_running?(shelly.id) do
          stop_shelly_task(shelly.id)
          {:ok, :stopped}
        else
          r = record_alert(shelly.id, user_id)
          if match?({:ok, _}, r), do: dispatch_to_shelly(shelly)
          r
        end

      %{shelly_id: shelly.id, shelly_name: shelly.name, result: result}
    end)
  end

  @doc """
  Triggers an alert on a specific shelly, provided the user has access to it.

  Returns `{:error, :forbidden}` if the shelly is not assigned to the user.
  Returns `{:error, :not_found}` if the shelly does not exist.
  """
  @spec trigger_shelly(User.t(), String.t()) ::
          {:ok, ShellyAlert.t()} | {:error, :forbidden | :not_found | Ecto.Changeset.t()}
  def trigger_shelly(%User{id: user_id} = _user, shelly_id) do
    shelly =
      from(s in Shelly,
        join: us in "user_shellies",
        on: us.shelly_id == s.id,
        where: s.id == ^shelly_id and us.user_id == type(^user_id, UUIDv7)
      )
      |> Repo.one()

    case shelly do
      nil ->
        case Repo.get(Shelly, shelly_id) do
          nil -> {:error, :not_found}
          _shelly -> {:error, :forbidden}
        end

      shelly ->
        result = record_alert(shelly.id, user_id)
        if match?({:ok, _}, result), do: dispatch_to_shelly(shelly)
        result
    end
  end

  @doc """
  Triggers alerts on all shellies assigned to the user.

  Returns a list of results, one per shelly.
  """
  @spec trigger_all_shellies(User.t()) :: [%{shelly_id: String.t(), result: term()}]
  def trigger_all_shellies(%User{id: user_id} = _user) do
    shellies =
      from(s in Shelly,
        join: us in "user_shellies",
        on: us.shelly_id == s.id,
        where: us.user_id == type(^user_id, UUIDv7)
      )
      |> Repo.all()

    Enum.map(shellies, fn shelly ->
      result = record_alert(shelly.id, user_id)
      if match?({:ok, _}, result), do: dispatch_to_shelly(shelly)
      %{shelly_id: shelly.id, shelly_name: shelly.name, result: result}
    end)
  end

  @task_registry __MODULE__.TaskRegistry

  @per_page 50

  @doc """
  Returns the number of shelly alert records matching the given filters.

  Accepts the same filter options as `list_alerts/1`.
  """
  @spec count_alerts(keyword() | map()) :: non_neg_integer()
  def count_alerts(opts \\ []) do
    opts
    |> build_alerts_query()
    |> Repo.aggregate(:count)
  end

  @doc """
  Lists shelly alert records with optional filtering, search, and pagination.

  Options:
    - `:search`    – text matched against user name, device ID, shelly name, or shelly IP (case-insensitive)
    - `:shelly_id` – filter to a specific shelly
    - `:user_id`   – filter to a specific user
    - `:page`      – page number (1-based, default 1)
    - `:per_page`  – records per page (default #{@per_page})
  """
  @spec list_alerts(keyword() | map()) :: [map()]
  def list_alerts(opts \\ []) do
    page = max(1, get_opt(opts, :page) || 1)
    per_page = get_opt(opts, :per_page) || @per_page
    offset = (page - 1) * per_page

    opts
    |> build_alerts_query()
    |> order_by([a, _u, _s], desc: a.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> select([a, u, s], %{
      id: a.id,
      triggered_at: a.inserted_at,
      user_id: u.id,
      user_name: u.name,
      device_id: u.device_id,
      shelly_id: s.id,
      shelly_name: s.name,
      shelly_ip: s.ip_address
    })
    |> Repo.all()
  end

  defp build_alerts_query(opts) do
    search = get_opt(opts, :search)
    shelly_id = get_opt(opts, :shelly_id)
    user_id = get_opt(opts, :user_id)

    from(a in ShellyAlert,
      join: u in User,
      on: u.id == a.user_id,
      join: s in Shelly,
      on: s.id == a.shelly_id
    )
    |> filter_by_shelly_id(shelly_id)
    |> filter_by_user_id(user_id)
    |> filter_by_search(search)
  end

  defp get_opt(opts, key) when is_map(opts), do: Map.get(opts, key) |> nilify_blank()
  defp get_opt(opts, key), do: Keyword.get(opts, key) |> nilify_blank()

  defp nilify_blank(nil), do: nil
  defp nilify_blank(""), do: nil
  defp nilify_blank(val), do: val

  defp filter_by_shelly_id(query, nil), do: query

  defp filter_by_shelly_id(query, shelly_id) do
    from([_a, _u, s] in query, where: s.id == ^shelly_id)
  end

  defp filter_by_user_id(query, nil), do: query

  defp filter_by_user_id(query, user_id) do
    from([_a, u, _s] in query, where: u.id == ^user_id)
  end

  defp filter_by_search(query, nil), do: query

  defp filter_by_search(query, search) do
    pattern = "%#{search}%"

    from([_a, u, s] in query,
      where:
        ilike(u.name, ^pattern) or
          ilike(u.device_id, ^pattern) or
          ilike(s.name, ^pattern) or
          ilike(s.ip_address, ^pattern)
    )
  end

  defp record_alert(shelly_id, user_id) do
    %ShellyAlert{}
    |> ShellyAlert.changeset(%{shelly_id: shelly_id, user_id: user_id})
    |> Repo.insert()
  end

  @doc """
  Stops a running shelly dispatch task for the given shelly ID, if one exists.

  Immediately kills the background task and turns the relay off.
  Returns `:ok` if the task was stopped, or `{:error, :not_running}` if no
  active task was found for the given shelly.
  """
  @spec stop_shelly_task(String.t()) :: :ok | {:error, :not_running}
  def stop_shelly_task(shelly_id) do
    case Agent.get_and_update(@task_registry, fn state ->
           {Map.get(state, shelly_id), Map.delete(state, shelly_id)}
         end) do
      nil ->
        {:error, :not_running}

      {pid, ip_address} ->
        Process.exit(pid, :kill)
        relay_switch(ip_address, "off", 0)
        :ok
    end
  end

  defp task_running?(shelly_id) do
    Agent.get(@task_registry, &Map.has_key?(&1, shelly_id))
  end

  defp dispatch_to_shelly(%Shelly{id: shelly_id, ip_address: ip_address}) do
    {:ok, pid} =
      Task.start(fn ->
        Enum.each(1..3, fn attempt ->
          if attempt > 1, do: Process.sleep(3_000)
          relay_switch(ip_address, "on")
          Process.sleep(5_000)
          relay_switch(ip_address, "off", 0)
        end)

        Agent.update(@task_registry, &Map.delete(&1, shelly_id))
      end)

    Agent.update(@task_registry, &Map.put(&1, shelly_id, {pid, ip_address}))
    :ok
  end

  defp relay_switch(ip_address, state, timer \\ 5) do
    url =
      if state == "off" do
        "http://#{ip_address}/relay/0?turn=off"
      else
        "http://#{ip_address}/relay/0?turn=#{state}&timer=#{timer}"
      end

    case Req.post(url) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    _ -> :ok
  end
end
