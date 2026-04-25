defmodule InstagrainWeb.PostLive.SliderComponent do
  use InstagrainWeb, :live_component

  alias InstagrainWeb.ImageFilters

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="relative w-full overflow-hidden shadow-sm"
      phx-hook="ImageSlider"
      data-count={length(@resources)}
    >
      <div class="flex transition-transform duration-300 ease-out items-center" data-slider-track>
        <div :for={resource <- @resources} class="w-full flex-shrink-0 relative">
          <img
            src={resource_url(resource, :full)}
            alt={resource.alt}
            class="w-full h-auto md:max-h-[80vh] pointer-events-none"
            draggable="false"
            style={ImageFilters.resource_filter_style(resource)}
          />
          <div
            :if={ImageFilters.resource_vignette_style(resource)}
            class="absolute inset-0 pointer-events-none"
            style={ImageFilters.resource_vignette_style(resource)}
          />
        </div>
      </div>

      <% resources_len = length(@resources) %>

      <%= if resources_len > 1 do %>
        <button
          type="button"
          data-slider-prev
          class={[
            "rounded-full cursor-pointer w-8 h-8 m-2 hidden",
            "flex items-center justify-center",
            "absolute left-0 top-1/2 translate-y-[-50%]",
            "bg-neutral-900/80 hover:bg-neutral-900/50",
            "transition ease-in-out duration-300"
          ]}
        >
          <InstagrainWeb.PostLive.FormComponent.left_chevron_icon class="text-white" />
        </button>

        <button
          type="button"
          data-slider-next
          class={[
            "rounded-full cursor-pointer w-8 h-8 m-2",
            "flex items-center justify-center",
            "absolute right-0 top-1/2 translate-y-[-50%]",
            "bg-neutral-900/80 hover:bg-neutral-900/50",
            "transition ease-in-out duration-300"
          ]}
        >
          <InstagrainWeb.PostLive.FormComponent.right_chevron_icon class="text-white" />
        </button>

        <div class="absolute bottom-3 left-1/2 -translate-x-1/2 flex gap-1.5" data-slider-dots>
          <div
            :for={i <- 0..(resources_len - 1)}
            class={[
              "w-1.5 h-1.5 rounded-full transition-colors duration-300",
              if(i == 0, do: "bg-blue-500", else: "bg-white/60")
            ]}
            data-dot-index={i}
          />
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end
end
