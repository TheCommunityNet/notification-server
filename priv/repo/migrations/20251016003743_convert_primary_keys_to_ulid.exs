defmodule ComnetWebsocket.Repo.Migrations.ConvertPrimaryKeysToUlid do
  use Ecto.Migration

  def up do
    # Convert devices table
    alter table(:devices) do
      add :new_id, :binary
    end

    execute "UPDATE devices SET new_id = decode(md5(random()::text), 'hex')"

    alter table(:devices) do
      remove :id
    end

    rename table(:devices), :new_id, to: :id

    execute "ALTER TABLE devices ADD PRIMARY KEY (id)"

    # Convert notifications table
    alter table(:notifications) do
      add :new_id, :binary
    end

    execute "UPDATE notifications SET new_id = decode(md5(random()::text), 'hex')"

    alter table(:notifications) do
      remove :id
    end

    rename table(:notifications), :new_id, to: :id

    execute "ALTER TABLE notifications ADD PRIMARY KEY (id)"

    # Convert device_activities table
    alter table(:device_activities) do
      add :new_id, :binary
    end

    execute "UPDATE device_activities SET new_id = decode(md5(random()::text), 'hex')"

    alter table(:device_activities) do
      remove :id
    end

    rename table(:device_activities), :new_id, to: :id

    execute "ALTER TABLE device_activities ADD PRIMARY KEY (id)"

    # Convert notification_trackings table
    alter table(:notification_trackings) do
      add :new_id, :binary
    end

    execute "UPDATE notification_trackings SET new_id = decode(md5(random()::text), 'hex')"

    alter table(:notification_trackings) do
      remove :id
    end

    rename table(:notification_trackings), :new_id, to: :id

    execute "ALTER TABLE notification_trackings ADD PRIMARY KEY (id)"
  end

  def down do
    # Convert back to UUID primary keys
    # This is a destructive operation and will lose data
    # In practice, you might want to create a backup first

    # Convert devices table
    alter table(:devices) do
      add :new_id, :uuid, default: fragment("uuid_generate_v4()")
    end

    execute "UPDATE devices SET new_id = uuid_generate_v4()"

    alter table(:devices) do
      remove :id
    end

    rename table(:devices), :new_id, to: :id

    execute "ALTER TABLE devices ADD PRIMARY KEY (id)"

    # Convert notifications table
    alter table(:notifications) do
      add :new_id, :uuid, default: fragment("uuid_generate_v4()")
    end

    execute "UPDATE notifications SET new_id = uuid_generate_v4()"

    alter table(:notifications) do
      remove :id
    end

    rename table(:notifications), :new_id, to: :id

    execute "ALTER TABLE notifications ADD PRIMARY KEY (id)"

    # Convert device_activities table
    alter table(:device_activities) do
      add :new_id, :uuid, default: fragment("uuid_generate_v4()")
    end

    execute "UPDATE device_activities SET new_id = uuid_generate_v4()"

    alter table(:device_activities) do
      remove :id
    end

    rename table(:device_activities), :new_id, to: :id

    execute "ALTER TABLE device_activities ADD PRIMARY KEY (id)"

    # Convert notification_trackings table
    alter table(:notification_trackings) do
      add :new_id, :uuid, default: fragment("uuid_generate_v4()")
    end

    execute "UPDATE notification_trackings SET new_id = uuid_generate_v4()"

    alter table(:notification_trackings) do
      remove :id
    end

    rename table(:notification_trackings), :new_id, to: :id

    execute "ALTER TABLE notification_trackings ADD PRIMARY KEY (id)"
  end
end
