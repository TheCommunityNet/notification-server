defmodule ComnetWebsocket.Constants do
  @moduledoc """
  Application-wide constants and configuration values.

  This module centralizes all magic strings, default values, and configuration
  constants used throughout the application.
  """

  # Notification types
  @notification_type_device "device"
  @notification_type_user "user"

  # Notification categories
  @notification_category_emergency "emergency"

  # Presence types
  @presence_type_guest "guest"
  @presence_type_user "user"

  # Scheduler intervals (in milliseconds)
  @expire_check_interval 600_000

  # API response messages
  @api_message_logged_in "logged in"
  @api_message_unauthorized "Unauthorized"

  # Error messages
  @error_invalid_params "Invalid parameters"

  # Notification types
  def notification_type_device, do: @notification_type_device
  def notification_type_user, do: @notification_type_user

  # Notification categories
  def notification_category_emergency, do: @notification_category_emergency

  # Presence types
  def presence_type_guest, do: @presence_type_guest
  def presence_type_user, do: @presence_type_user

  # Scheduler intervals
  def expire_check_interval, do: @expire_check_interval

  # API response messages
  def api_message_logged_in, do: @api_message_logged_in
  def api_message_unauthorized, do: @api_message_unauthorized

  # Error messages
  def error_invalid_params, do: @error_invalid_params
end
