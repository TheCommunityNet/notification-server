defmodule Mix.Tasks.Copy.VendorJs do
  @shortdoc "Copies vendor JS (popover, css-anchor-positioning) to priv/static for serving"
  @moduledoc false

  use Mix.Task

  @vendor_js [
    "popover.min.js",
    "popover.min.js.map",
    "css-anchor-positioning.js",
    "css-anchor-positioning.js.map"
  ]

  @impl Mix.Task
  def run(_args) do
    base = File.cwd!()
    src_dir = Path.join(base, "assets/vendor/js")
    dest_dir = Path.join(base, "priv/static/assets/js")

    File.mkdir_p!(dest_dir)

    for name <- @vendor_js do
      src = Path.join(src_dir, name)
      dest = Path.join(dest_dir, name)

      if File.exists?(src) do
        File.cp!(src, dest)
        Mix.shell().info("Copied #{name}")
      end
    end
  end
end
