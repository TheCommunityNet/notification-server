defmodule ComnetWebsocketWeb.AdminComponents do
  use Phoenix.Component

  @doc """
  Renders a form field label with an optional required indicator.

  ## Examples

      <.label>Name</.label>
      <.label required>Email</.label>
  """
  attr :required, :boolean, default: false
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label class={["block text-xs font-medium text-gray-700 mb-1", @class]}>
      <%= render_slot(@inner_block) %><span :if={@required} class="text-red-500 ml-0.5">*</span>
    </label>
    """
  end

  @doc """
  Renders a form input (text, number, password, textarea, select) with an optional label.

  ## Examples

      <.input label="Name" name="user[name]" required placeholder="John Doe" />
      <.input type="textarea" label="Content" name="notification[content]" rows={3} />
      <.input type="select" label="Category" name="notification[category]"
              options={[{"Normal", "normal"}, {"Emergency", "emergency"}]} />
  """
  attr :type, :string, default: "text"
  attr :label, :string, default: nil
  attr :name, :string, required: true
  attr :value, :any, default: nil
  attr :placeholder, :string, default: nil
  attr :required, :boolean, default: false
  attr :rows, :integer, default: 3
  attr :min, :string, default: nil
  attr :max, :string, default: nil
  attr :options, :list, default: []
  attr :class, :string, default: nil
  attr :rest, :global

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} required={@required}><%= @label %></.label>
      <select
        name={@name}
        class={[
          "w-full px-3 py-2 text-sm border border-gray-300 rounded-lg bg-white",
          "focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent",
          @class
        ]}
        {@rest}
      >
        <option :for={{opt_label, val} <- @options} value={val} selected={@value == val}>
          <%= opt_label %>
        </option>
      </select>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} required={@required}><%= @label %></.label>
      <textarea
        name={@name}
        rows={@rows}
        placeholder={@placeholder}
        required={@required}
        class={[
          "w-full px-3 py-2 text-sm border border-gray-300 rounded-lg resize-none",
          "focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent",
          @class
        ]}
        {@rest}
      ><%= @value %></textarea>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div>
      <.label :if={@label} required={@required}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        value={@value}
        placeholder={@placeholder}
        required={@required}
        min={@min}
        max={@max}
        class={[
          "w-full px-3 py-2 text-sm border border-gray-300 rounded-lg",
          "focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent",
          @class
        ]}
        {@rest}
      />
    </div>
    """
  end

  @doc """
  Renders a button with color and size variants.

  ## Examples

      <.button>Create User</.button>
      <.button color="emerald">Register</.button>
      <.button color="red" size="sm" type="button">Delete</.button>
      <.button color="ghost" size="sm">Cancel</.button>
  """
  attr :type, :string, default: "submit"
  attr :color, :string, default: "indigo"
  attr :size, :string, default: "md"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[button_base_class(@size), button_color_class(@color), @class]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_base_class("sm"),
    do: "inline-flex items-center px-3 py-1.5 text-xs font-medium rounded-lg transition-colors"

  defp button_base_class(_),
    do: "inline-flex items-center px-5 py-2 text-sm font-medium rounded-lg transition-colors"

  defp button_color_class("indigo"), do: "text-white bg-indigo-600 hover:bg-indigo-700"
  defp button_color_class("emerald"), do: "text-white bg-emerald-600 hover:bg-emerald-700"
  defp button_color_class("amber"), do: "text-white bg-amber-600 hover:bg-amber-700"
  defp button_color_class("red"), do: "text-white bg-red-600 hover:bg-red-700"
  defp button_color_class("indigo-soft"), do: "text-indigo-700 bg-indigo-50 hover:bg-indigo-100"

  defp button_color_class("emerald-soft"),
    do: "text-emerald-700 bg-emerald-50 hover:bg-emerald-100"

  defp button_color_class("red-soft"), do: "text-red-700 bg-red-50 hover:bg-red-100"
  defp button_color_class("ghost"), do: "text-gray-600 bg-gray-100 hover:bg-gray-200"
  defp button_color_class(_), do: "text-white bg-indigo-600 hover:bg-indigo-700"

  @doc """
  Renders a colored badge/pill.

  ## Examples

      <.badge color="red">Emergency</.badge>
      <.badge color="blue">Device</.badge>
      <.badge color="green">Active</.badge>
  """
  attr :color, :string, default: "gray"
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def badge(assigns) do
    ~H"""
    <span class={[
      "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium",
      badge_color_class(@color),
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  defp badge_color_class("red"), do: "bg-red-100 text-red-700"
  defp badge_color_class("green"), do: "bg-green-50 text-green-600"
  defp badge_color_class("blue"), do: "bg-blue-100 text-blue-700"
  defp badge_color_class("purple"), do: "bg-purple-100 text-purple-700"
  defp badge_color_class("amber"), do: "bg-amber-100 text-amber-700"
  defp badge_color_class("indigo"), do: "bg-indigo-100 text-indigo-700"
  defp badge_color_class(_), do: "bg-gray-100 text-gray-600"

  @doc """
  Renders a white card container with an optional title and subtitle.

  ## Examples

      <.card title="Create New User">
        <p>Content here</p>
      </.card>
  """
  attr :title, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["bg-white rounded-xl shadow-sm border border-gray-200", @class]}>
      <div :if={@title} class="px-6 py-4 border-b border-gray-100">
        <h3 class="text-base font-semibold text-gray-900"><%= @title %></h3>
      </div>
      <div class="p-6">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a dropdown menu using the HTML Popover API + CSS Anchor Positioning.
  Provides light-dismiss (click outside), Escape key, and top-layer rendering
  with no JavaScript required.

  Requires a unique `id` per dropdown instance.

  ## Example

      <.dropdown id="user-actions-123">
        <.dropdown_item href="/admin/users/123/edit">Edit</.dropdown_item>
        <form action="/admin/users/123" method="post">
          <input type="hidden" name="_method" value="delete" />
          <.dropdown_item danger>Delete</.dropdown_item>
        </form>
      </.dropdown>
  """
  attr :id, :string, required: true
  slot :inner_block, required: true

  def dropdown(assigns) do
    ~H"""
    <button
      popovertarget={@id}
      class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium
             text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-lg cursor-pointer select-none">
      Actions
      <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>
    <div
      id={@id}
      popover
      style="position: absolute; inset: auto; margin: 0;"
      class="bg-white border border-gray-200 rounded-xl shadow-lg py-1 min-w-44 text-sm">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a single item inside a `<.dropdown>`.
  Use as a link (`href`) or as a submit button inside a `<form>` (no href).
  """
  attr :href, :string, default: nil
  attr :danger, :boolean, default: false
  attr :rest, :global
  slot :inner_block, required: true

  def dropdown_item(%{href: href} = assigns) when not is_nil(href) do
    ~H"""
    <a href={@href}
       class={[
         "flex w-full items-center px-4 py-2 text-sm hover:bg-gray-50 transition-colors",
         if(@danger, do: "text-red-600", else: "text-gray-700")
       ]}
       {@rest}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  def dropdown_item(assigns) do
    ~H"""
    <button type="submit"
            class={[
              "flex w-full items-center px-4 py-2 text-sm hover:bg-gray-50 transition-colors text-left",
              if(@danger, do: "text-red-600", else: "text-gray-700")
            ]}
            {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders a thin divider line inside a `<.dropdown>`.
  """
  def dropdown_divider(assigns) do
    ~H"""
    <div class="my-1 border-t border-gray-100"></div>
    """
  end

  @doc """
  Renders a stat card for the dashboard.
  """
  attr :label, :string, required: true
  attr :value, :integer, required: true
  attr :href, :string, required: true
  attr :link_label, :string, required: true
  attr :color, :string, default: "indigo"
  slot :icon, required: true

  def stat_card(assigns) do
    ~H"""
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <div class="flex items-center justify-between mb-2">
        <p class="text-sm font-medium text-gray-500"><%= @label %></p>
        <div class={["w-9 h-9 rounded-lg flex items-center justify-center", stat_bg_class(@color)]}>
          <span class={stat_icon_class(@color)}>
            <%= render_slot(@icon) %>
          </span>
        </div>
      </div>
      <p class="text-3xl font-bold text-gray-900"><%= @value %></p>
      <a href={@href} class={["text-xs hover:underline mt-1 inline-block", stat_link_class(@color)]}>
        <%= @link_label %> →
      </a>
    </div>
    """
  end

  defp stat_bg_class("indigo"), do: "bg-indigo-50"
  defp stat_bg_class("emerald"), do: "bg-emerald-50"
  defp stat_bg_class("amber"), do: "bg-amber-50"
  defp stat_bg_class(_), do: "bg-gray-50"

  defp stat_icon_class("indigo"), do: "text-indigo-600"
  defp stat_icon_class("emerald"), do: "text-emerald-600"
  defp stat_icon_class("amber"), do: "text-amber-600"
  defp stat_icon_class(_), do: "text-gray-600"

  defp stat_link_class("indigo"), do: "text-indigo-600"
  defp stat_link_class("emerald"), do: "text-emerald-600"
  defp stat_link_class("amber"), do: "text-amber-600"
  defp stat_link_class(_), do: "text-gray-600"
end
