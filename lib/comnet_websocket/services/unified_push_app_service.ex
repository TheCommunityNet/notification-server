defmodule ComnetWebsocket.Services.UnifiedPushAppService do
  @moduledoc """
  Service module for managing unified push apps.
  """

  alias ComnetWebsocket.Models.UnifiedPushApp
  alias ComnetWebsocket.Repo

  @type unified_push_app_attrs :: %{
          optional(:app_id) => String.t(),
          optional(:connector_token) => String.t(),
          optional(:device_id) => String.t()
        }

  @type unified_push_app_result ::
          {:ok, UnifiedPushApp.t()} | {:error, Ecto.Changeset.t() | :not_found}

  @doc """
  Finds a unified push app by id.

  ## Parameters
  - `id` - The id of the unified push app

  ## Returns
  - `{:ok, unified_push_app}` - Unified push app found
  - `{:error, :not_found}` - Unified push app not found
  """
  @spec find_unified_push_app_by_id(String.t()) :: unified_push_app_result()
  def find_unified_push_app_by_id(id) do
    case Repo.get(UnifiedPushApp, id) do
      nil ->
        {:error, :not_found}

      unified_push_app ->
        {:ok, unified_push_app}
    end
  end

  @doc """
  Creates a new unified push app.
  """
  @spec create_unified_push_app(unified_push_app_attrs()) :: unified_push_app_result()
  def create_unified_push_app(attrs) do
    %UnifiedPushApp{}
    |> UnifiedPushApp.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a unified push app.
  """
  @spec delete_unified_push_app(unified_push_app_attrs()) :: unified_push_app_result()
  def delete_unified_push_app(attrs) do
    case Repo.get_by(UnifiedPushApp,
           app_id: attrs.app_id,
           connector_token: attrs.connector_token,
           device_id: attrs.device_id
         ) do
      nil ->
        {:error, :not_found}

      unified_push_app ->
        Repo.delete(unified_push_app)
    end
  end
end
