defmodule InstagrainWeb.ImageFilters do
  @moduledoc """
  Helper functions for Instagram-like image filters and adjustments.
  Generates CSS filter strings for both edit previews and image display.
  """

  @filters [
    {"original", "Original"},
    {"aden", "Aden"},
    {"clarendon", "Clarendon"},
    {"crema", "Crema"},
    {"gingham", "Gingham"},
    {"juno", "Juno"},
    {"lark", "Lark"},
    {"ludwig", "Ludwig"},
    {"moon", "Moon"},
    {"perpetua", "Perpetua"},
    {"reyes", "Reyes"},
    {"slumber", "Slumber"}
  ]

  @adjustment_options [
    {"brightness", "Brightness", -100, 100},
    {"contrast", "Contrast", -100, 100},
    {"fade", "Fade", 0, 100},
    {"saturation", "Saturation", -100, 100},
    {"temperature", "Temperature", -100, 100},
    {"vignette", "Vignette", 0, 100}
  ]

  def filters, do: @filters
  def adjustment_options, do: @adjustment_options

  def default_adjustments do
    %{
      "brightness" => 0,
      "contrast" => 0,
      "fade" => 0,
      "saturation" => 0,
      "temperature" => 0,
      "vignette" => 0
    }
  end

  @doc """
  Computes the CSS filter string for a given filter preset and adjustments map.
  Returns nil if no filter is needed.
  """
  def compute_filter_css(filter, adjustments) do
    filter_css = preset_to_css(filter)
    adj_css = adjustments_to_css(adjustments)
    combined = String.trim("#{filter_css} #{adj_css}")
    if combined == "", do: nil, else: "filter: #{combined};"
  end

  @doc """
  Computes the CSS filter style for a given filter preset only (for thumbnails).
  """
  def preset_style(filter) do
    css = preset_to_css(filter)
    if css == "", do: nil, else: "filter: #{css};"
  end

  @doc """
  Returns the vignette overlay style, or nil if vignette is 0.
  """
  def vignette_style(adjustments) do
    vignette = get_adj(adjustments, "vignette")

    if vignette > 0 do
      opacity = Float.round(vignette / 100 * 0.6, 2)
      "background: radial-gradient(circle, transparent 40%, rgba(0,0,0,#{opacity}) 100%);"
    end
  end

  @doc """
  Computes filter CSS for a resource loaded from the database.
  """
  def resource_filter_style(resource) do
    filter = resource.filter || "original"
    adjustments = resource.adjustments || %{}
    compute_filter_css(filter, adjustments)
  end

  def resource_vignette_style(resource) do
    adjustments = resource.adjustments || %{}
    vignette_style(adjustments)
  end

  # Filter presets - CSS filter combinations approximating Instagram filters
  defp preset_to_css("original"), do: ""

  defp preset_to_css("aden"),
    do: "hue-rotate(-20deg) contrast(0.9) saturate(0.85) brightness(1.2)"

  defp preset_to_css("clarendon"), do: "contrast(1.2) saturate(1.35)"
  defp preset_to_css("crema"), do: "sepia(0.5) contrast(0.9) brightness(1.1) saturate(0.9)"
  defp preset_to_css("gingham"), do: "brightness(1.05) hue-rotate(-10deg) sepia(0.04)"
  defp preset_to_css("juno"), do: "sepia(0.35) contrast(1.15) brightness(1.15) saturate(1.8)"
  defp preset_to_css("lark"), do: "contrast(0.9) brightness(1.15) saturate(1.1)"
  defp preset_to_css("ludwig"), do: "brightness(1.05) saturate(1.1) contrast(1.05)"
  defp preset_to_css("moon"), do: "grayscale(1) contrast(1.1) brightness(1.1)"
  defp preset_to_css("perpetua"), do: "brightness(1.15) contrast(0.9) saturate(1.1)"
  defp preset_to_css("reyes"), do: "sepia(0.22) brightness(1.1) contrast(0.85) saturate(0.75)"
  defp preset_to_css("slumber"), do: "saturate(0.66) brightness(1.05) sepia(0.1)"
  defp preset_to_css(_), do: ""

  # Convert adjustments map to CSS filter string
  defp adjustments_to_css(adjustments) do
    []
    |> maybe_add(
      get_adj(adjustments, "brightness") != 0,
      "brightness(#{rv(1 + get_adj(adjustments, "brightness") / 200)})"
    )
    |> maybe_add(
      get_adj(adjustments, "contrast") != 0,
      "contrast(#{rv(1 + get_adj(adjustments, "contrast") / 200)})"
    )
    |> maybe_add(
      get_adj(adjustments, "fade") > 0,
      "contrast(#{rv(1 - get_adj(adjustments, "fade") / 250)}) brightness(#{rv(1 + get_adj(adjustments, "fade") / 400)})"
    )
    |> maybe_add(
      get_adj(adjustments, "saturation") != 0,
      "saturate(#{rv(1 + get_adj(adjustments, "saturation") / 100)})"
    )
    |> maybe_add(
      get_adj(adjustments, "temperature") > 0,
      "sepia(#{rv(get_adj(adjustments, "temperature") / 300)})"
    )
    |> maybe_add(
      get_adj(adjustments, "temperature") < 0,
      "hue-rotate(#{rv(get_adj(adjustments, "temperature") / 3)}deg)"
    )
    |> Enum.reverse()
    |> Enum.join(" ")
  end

  defp get_adj(adjustments, key) do
    # Handle both atom and string keys
    Map.get(adjustments, key) || Map.get(adjustments, String.to_atom(key)) || 0
  end

  defp maybe_add(list, true, value), do: [value | list]
  defp maybe_add(list, false, _value), do: list

  # Round to 2 decimal places for clean CSS
  defp rv(value), do: Float.round(value / 1, 2)
end
