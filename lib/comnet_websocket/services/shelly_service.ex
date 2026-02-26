defmodule ComnetWebsocket.Services.ShellyService do
  import Ecto.Query

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.Shelly

  @spec list_shellies(keyword()) :: [Shelly.t()]
  def list_shellies(opts \\ []) do
    page = max(1, Keyword.get(opts, :page, 1))
    per_page = Keyword.get(opts, :per_page, 25)
    offset = (page - 1) * per_page

    Repo.all(
      from s in Shelly,
        order_by: [desc: s.inserted_at],
        limit: ^per_page,
        offset: ^offset
    )
  end

  @spec get_shelly(String.t()) :: Shelly.t() | nil
  def get_shelly(id) do
    Repo.get(Shelly, id)
  end

  @spec update_shelly(Shelly.t(), map()) :: {:ok, Shelly.t()} | {:error, Ecto.Changeset.t()}
  def update_shelly(shelly, attrs) do
    shelly
    |> Shelly.update_changeset(attrs)
    |> Repo.update()
  end

  @spec create_shelly(map()) :: {:ok, Shelly.t()} | {:error, Ecto.Changeset.t()}
  def create_shelly(attrs) do
    %Shelly{}
    |> Shelly.changeset(attrs)
    |> Repo.insert()
  end

  @spec delete_shelly(Shelly.t()) :: {:ok, Shelly.t()} | {:error, Ecto.Changeset.t()}
  def delete_shelly(shelly) do
    Repo.delete(shelly)
  end

  @spec count_shellies() :: integer()
  def count_shellies do
    Repo.aggregate(Shelly, :count)
  end
end
