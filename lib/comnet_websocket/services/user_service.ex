defmodule ComnetWebsocket.Services.UserService do
  import Ecto.Query

  alias ComnetWebsocket.Repo
  alias ComnetWebsocket.Models.{User, Shelly}

  @spec list_users() :: [User.t()]
  def list_users do
    Repo.all(from u in User, order_by: [desc: u.inserted_at])
  end

  @spec list_users_with_shellies(keyword()) :: [User.t()]
  def list_users_with_shellies(opts \\ []) do
    page = max(1, Keyword.get(opts, :page, 1))
    per_page = Keyword.get(opts, :per_page, 20)
    offset = (page - 1) * per_page

    User
    |> order_by([u], desc: u.inserted_at)
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload(:shellies)
  end

  @spec get_user(String.t()) :: User.t() | nil
  def get_user(id) do
    Repo.get(User, id)
  end

  @spec assign_shelly(User.t(), String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def assign_shelly(user, shelly_id) do
    user = Repo.preload(user, :shellies)
    shelly = Repo.get(Shelly, shelly_id)

    if shelly do
      user
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:shellies, [shelly | user.shellies])
      |> Repo.update()
    else
      {:error, :not_found}
    end
  end

  @spec remove_shelly(User.t(), String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def remove_shelly(user, shelly_id) do
    user = Repo.preload(user, :shellies)
    updated = Enum.reject(user.shellies, &(to_string(&1.id) == to_string(shelly_id)))

    user
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:shellies, updated)
    |> Repo.update()
  end

  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    %User{}
    |> User.admin_create_changeset(attrs)
    |> Repo.insert()
  end

  @spec get_user_by_otp_token(String.t()) :: User.t() | nil
  def get_user_by_otp_token(otp_token) do
    Repo.get_by(User, otp_token: otp_token)
  end

  @spec get_user_by_access_token(String.t()) :: User.t() | nil
  def get_user_by_access_token(access_token) do
    Repo.get_by(User, access_token: access_token)
  end

  @spec verify_otp(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :invalid_otp} | {:error, Ecto.Changeset.t()}
  def verify_otp(otp_token, device_id) do
    case get_user_by_otp_token(otp_token) do
      nil ->
        {:error, :invalid_otp}

      user ->
        user
        |> User.verify_otp_changeset(device_id)
        |> Repo.update()
    end
  end

  @spec generate_otp_token(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def generate_otp_token(user, retries_left \\ 3) do
    case user |> User.generate_otp_changeset() |> Repo.update() do
      {:ok, user} ->
        {:ok, user}

      {:error, %{errors: errors} = changeset} when retries_left > 0 ->
        if otp_token_unique_error?(errors) do
          user = Repo.get(User, user.id)
          generate_otp_token(user, retries_left - 1)
        else
          {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp otp_token_unique_error?(errors) do
    case Keyword.get(errors, :otp_token) do
      {_, opts} when is_list(opts) -> Keyword.get(opts, :constraint) == :unique
      _ -> false
    end
  end

  @spec regenerate_access_token(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def regenerate_access_token(user) do
    user
    |> User.regenerate_access_token_changeset()
    |> Repo.update()
  end

  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(user) do
    Repo.delete(user)
  end

  @spec count_users() :: integer()
  def count_users do
    Repo.aggregate(User, :count)
  end
end
