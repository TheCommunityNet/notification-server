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
      {render_slot(@inner_block)}<span :if={@required} class="text-red-500 ml-0.5">*</span>
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
      <.label :if={@label} required={@required}>{@label}</.label>
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
          {opt_label}
        </option>
      </select>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} required={@required}>{@label}</.label>
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
      <.label :if={@label} required={@required}>{@label}</.label>
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
  Renders a custom-styled checkbox with an optional label (slot content).

  The native checkbox is visually hidden; a styled box with checkmark is shown instead.
  Use the inner block for the label text (e.g. item name and secondary info).

  ## Examples

      <.checkbox name="user[shelly_ids][]" value={s.id} checked={assigned?}>
        <span class="text-sm text-gray-700">{s.name}</span>
        <span class="text-xs text-gray-400">({s.ip_address})</span>
      </.checkbox>
  """
  attr :name, :string, required: true
  attr :value, :any, required: true
  attr :checked, :boolean, default: false
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def checkbox(assigns) do
    assigns =
      assign(assigns, :input_id, assigns[:id] || "checkbox-#{System.unique_integer([:positive])}")

    ~H"""
    <label
      for={@input_id}
      class={[
        "flex items-center gap-3 cursor-pointer rounded-lg py-2.5 px-3 -mx-1 transition-colors",
        "hover:bg-gray-50 focus-within:bg-gray-50",
        @class
      ]}
    >
      <span class="relative flex size-4 flex-shrink-0 items-center justify-center">
        <input
          type="checkbox"
          id={@input_id}
          name={@name}
          value={@value}
          checked={@checked}
          class="sr-only peer"
          {@rest}
        />
        <span
          class={[
            "absolute inset-0 rounded border-1 transition-colors",
            "border-gray-300 bg-white peer-checked:border-indigo-600 peer-checked:bg-indigo-600",
            "peer-focus:ring-2 peer-focus:ring-indigo-500 peer-focus:ring-offset-1"
          ]}
          aria-hidden="true"
        >
        </span>
        <span
          class="absolute inset-0 flex items-center justify-center opacity-0 transition-opacity peer-checked:opacity-100 pointer-events-none"
          aria-hidden="true"
        >
          <svg
            class="h-3 w-3 text-white"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 12 12"
            fill="none"
            stroke="currentColor"
            stroke-width="2.5"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <polyline points="2 6 5 9 10 3" />
          </svg>
        </span>
      </span>
      <span class="flex flex-wrap items-baseline gap-x-1.5 min-w-0">
        {render_slot(@inner_block)}
      </span>
    </label>
    """
  end

  @doc """
  Renders a toggle switch for boolean form fields (e.g. is_banned).

  Use with a hidden input before it so unchecked state submits "false":
  `<input type="hidden" name="user[is_banned]" value="false" />`
  Then the switch checkbox has value "true"; when checked both are sent.

  ## Examples

      <input type="hidden" name="user[is_banned]" value="false" />
      <.switch name="user[is_banned]" label="Banned" checked={@user.is_banned} />
  """
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :checked, :boolean, default: false
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def switch(assigns) do
    assigns =
      assign(assigns, :input_id, assigns[:id] || "switch-#{System.unique_integer([:positive])}")

    ~H"""
    <div class={["flex items-center justify-between gap-3", @class]}>
      <label for={@input_id} class="block text-xs font-medium text-gray-700">
        {@label}
      </label>
      <label
        for={@input_id}
        class="relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer items-center rounded-full focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2"
      >
        <input
          type="checkbox"
          id={@input_id}
          name={@name}
          value="true"
          checked={@checked}
          class="sr-only peer"
          {@rest}
        />
        <span
          class="absolute inset-0 rounded-full border border-gray-200 bg-gray-200 transition-colors peer-checked:border-indigo-600 peer-checked:bg-indigo-600"
          aria-hidden="true"
        >
        </span>
        <span
          class="pointer-events-none absolute left-0.5 top-0.5 h-5 w-5 rounded-full bg-white shadow transition-transform peer-checked:translate-x-5"
          aria-hidden="true"
        >
        </span>
      </label>
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
  attr :form, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[button_base_class(@size), button_color_class(@color), @class]}
      {@rest}
      form={@form}
    >
      {render_slot(@inner_block)}
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
      {render_slot(@inner_block)}
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
  slot :footer

  def card(assigns) do
    ~H"""
    <div class={["bg-white rounded-xl shadow-sm border border-gray-200", @class]}>
      <div :if={@title} class="px-6 py-4 border-b border-gray-100">
        <h3 class="text-base font-semibold text-gray-900">{@title}</h3>
      </div>
      <div class="p-6">
        {render_slot(@inner_block)}
      </div>
      <div
        :if={@footer != []}
        class="px-6 py-4 border-t border-gray-100 bg-gray-50/50 rounded-b-xl flex flex-wrap gap-3 items-center"
      >
        {render_slot(@footer)}
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
      style="anchor-name: --{@id};"
      class="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-medium
             text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-lg cursor-pointer select-none"
    >
      Actions
      <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>
    <div
      id={@id}
      popover
      class="bg-white border border-gray-200 rounded-xl shadow-lg py-1 min-w-44 text-sm absolute inset-auto m-0 mt-1.5 popover"
      style="position-anchor: --{@id};"
    >
      {render_slot(@inner_block)}
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
    <a
      href={@href}
      class={[
        "flex w-full items-center px-4 py-2 text-sm hover:bg-gray-50 transition-colors",
        if(@danger, do: "text-red-600", else: "text-gray-700")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end

  def dropdown_item(assigns) do
    ~H"""
    <button
      type="submit"
      class={[
        "flex w-full items-center px-4 py-2 text-sm hover:bg-gray-50 transition-colors text-left",
        if(@danger, do: "text-red-600", else: "text-gray-700")
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
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
  attr :href, :string, default: nil
  attr :link_label, :string, default: nil
  attr :color, :string, default: "indigo"
  slot :icon, required: true

  def stat_card(assigns) do
    ~H"""
    <div class="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <div class="flex items-center justify-between mb-2">
        <p class="text-sm font-medium text-gray-500">{@label}</p>
        <div class={["w-9 h-9 rounded-lg flex items-center justify-center", stat_bg_class(@color)]}>
          <span class={stat_icon_class(@color)}>
            {render_slot(@icon)}
          </span>
        </div>
      </div>
      <p class="text-3xl font-bold text-gray-900">{@value}</p>
      <a
        :if={@href}
        href={@href}
        class={["text-xs hover:underline mt-1 inline-block", stat_link_class(@color)]}
      >
        {@link_label} →
      </a>
      <p :if={!@href && @link_label} class={["text-xs mt-1", stat_link_class(@color)]}>
        {@link_label}
      </p>
    </div>
    """
  end

  defp stat_bg_class("indigo"), do: "bg-indigo-50"
  defp stat_bg_class("emerald"), do: "bg-emerald-50"
  defp stat_bg_class("amber"), do: "bg-amber-50"
  defp stat_bg_class("red"), do: "bg-red-50"
  defp stat_bg_class("teal"), do: "bg-teal-50"
  defp stat_bg_class(_), do: "bg-gray-50"

  defp stat_icon_class("indigo"), do: "text-indigo-600"
  defp stat_icon_class("emerald"), do: "text-emerald-600"
  defp stat_icon_class("amber"), do: "text-amber-600"
  defp stat_icon_class("red"), do: "text-red-600"
  defp stat_icon_class("teal"), do: "text-teal-600"
  defp stat_icon_class(_), do: "text-gray-600"

  defp stat_link_class("indigo"), do: "text-indigo-600"
  defp stat_link_class("emerald"), do: "text-emerald-600"
  defp stat_link_class("amber"), do: "text-amber-600"
  defp stat_link_class("red"), do: "text-red-600"
  defp stat_link_class("teal"), do: "text-teal-600"
  defp stat_link_class(_), do: "text-gray-600"

  @doc """
  Renders a pagination control for admin list pages.

  ## Attributes

    * `page`        – current page (1-based)
    * `total_pages` – total number of pages
    * `base_path`   – URL path (with existing query params, without `page=`)
    * `total_count` – total record count, displayed as summary text
    * `per_page`    – records per page, used to compute the shown range

  ## Example

      <.pagination page={@page} total_pages={@total_pages}
                   base_path={@base_path} total_count={@total_count} per_page={25} />
  """
  attr :page, :integer, required: true
  attr :total_pages, :integer, required: true
  attr :base_path, :string, required: true
  attr :total_count, :integer, required: true
  attr :per_page, :integer, required: true

  def pagination(assigns) do
    assigns = assign(assigns, :page_numbers, page_range(assigns.page, assigns.total_pages))

    ~H"""
    <div class="px-6 py-3 border-t border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-3">
      <p class="text-xs text-gray-500 order-2 sm:order-1">
        Showing
        <span class="font-medium text-gray-700">
          {min((@page - 1) * @per_page + 1, @total_count)}–{min(@page * @per_page, @total_count)}
        </span>
        of <span class="font-medium text-gray-700">{@total_count}</span>
      </p>

      <nav class="flex items-center gap-1 order-1 sm:order-2" aria-label="Pagination">
        <%!-- Previous --%>
        <%= if @page > 1 do %>
          <a
            href={page_href(@base_path, @page - 1)}
            class="px-2.5 py-1.5 text-xs font-medium text-gray-600 bg-white border border-gray-200
                    hover:bg-gray-50 hover:text-gray-900 rounded-lg transition-colors"
          >
            ← Prev
          </a>
        <% else %>
          <span class="px-2.5 py-1.5 text-xs font-medium text-gray-300 bg-white border border-gray-100
                       rounded-lg cursor-not-allowed select-none">
            ← Prev
          </span>
        <% end %>

        <%!-- Page numbers --%>
        <%= for item <- @page_numbers do %>
          <%= if item == nil do %>
            <span class="px-2 py-1.5 text-xs text-gray-400 select-none">…</span>
          <% else %>
            <a
              href={page_href(@base_path, item)}
              class={[
                "min-w-[2rem] px-2.5 py-1.5 text-xs font-medium rounded-lg transition-colors text-center",
                if(item == @page,
                  do: "bg-indigo-600 text-white border border-indigo-600",
                  else:
                    "text-gray-600 bg-white border border-gray-200 hover:bg-gray-50 hover:text-gray-900"
                )
              ]}
            >
              {item}
            </a>
          <% end %>
        <% end %>

        <%!-- Next --%>
        <%= if @page < @total_pages do %>
          <a
            href={page_href(@base_path, @page + 1)}
            class="px-2.5 py-1.5 text-xs font-medium text-gray-600 bg-white border border-gray-200
                    hover:bg-gray-50 hover:text-gray-900 rounded-lg transition-colors"
          >
            Next →
          </a>
        <% else %>
          <span class="px-2.5 py-1.5 text-xs font-medium text-gray-300 bg-white border border-gray-100
                       rounded-lg cursor-not-allowed select-none">
            Next →
          </span>
        <% end %>
      </nav>
    </div>
    """
  end

  defp page_href(base_path, page) do
    sep = if String.contains?(base_path, "?"), do: "&", else: "?"
    "#{base_path}#{sep}page=#{page}"
  end

  defp page_range(_current, total) when total <= 7 do
    Enum.to_list(1..total)
  end

  defp page_range(current, total) do
    # Always include first, last, current and its immediate neighbours
    always = MapSet.new([1, total, current, max(1, current - 1), min(total, current + 1)])

    sorted = always |> MapSet.to_list() |> Enum.sort()

    # Insert nil (ellipsis) between non-consecutive page numbers
    sorted
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce([hd(sorted)], fn [a, b], acc ->
      if b - a > 1, do: acc ++ [nil, b], else: acc ++ [b]
    end)
  end
end
