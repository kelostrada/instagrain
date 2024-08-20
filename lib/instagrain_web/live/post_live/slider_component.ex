defmodule InstagrainWeb.PostLive.SliderComponent do
  use InstagrainWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="relative w-full overflow-hidden shadow-sm">
      <div class={[
        "flex transition-transform duration-500 items-center",
        translate_full(@current_resource_index)
      ]}>
        <div :for={resource <- @resources} class="w-full flex-shrink-0">
          <img
            src={~p"/uploads/#{resource.file}"}
            alt={resource.alt}
            class="w-full h-auto max-h-[80vh]"
          />
        </div>
      </div>

      <% resources_len = length(@resources) %>

      <div
        :if={resources_len > 1 && @current_resource_index > 0}
        phx-click="previous-resource"
        phx-target={@myself}
        class={[
          "rounded-full cursor-pointer w-8 h-8 m-2",
          "flex items-center justify-center",
          "absolute left-0 top-1/2 translate-y-[-50%]",
          "bg-neutral-900/80 hover:bg-neutral-900/50",
          "transition ease-in-out duration-300"
        ]}
      >
        <InstagrainWeb.PostLive.FormComponent.left_chevron_icon class="text-white" />
      </div>

      <div
        :if={resources_len > 1 && @current_resource_index < resources_len - 1}
        phx-click="next-resource"
        phx-target={@myself}
        class={[
          "rounded-full cursor-pointer w-8 h-8 m-2",
          "flex items-center justify-center",
          "absolute right-0 top-1/2 translate-y-[-50%]",
          "bg-neutral-900/80 hover:bg-neutral-900/50",
          "transition ease-in-out duration-300"
        ]}
      >
        <InstagrainWeb.PostLive.FormComponent.right_chevron_icon class="text-white" />
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign_new(socket, :current_resource_index, fn -> 0 end)}
  end

  @impl true
  def handle_event("next-resource", _, socket) do
    {:noreply, assign(socket, current_resource_index: socket.assigns.current_resource_index + 1)}
  end

  def handle_event("previous-resource", _, socket) do
    {:noreply, assign(socket, current_resource_index: socket.assigns.current_resource_index - 1)}
  end

  defp translate_full(0), do: ""
  defp translate_full(1), do: "-translate-x-[100%]"
  defp translate_full(2), do: "-translate-x-[200%]"
  defp translate_full(3), do: "-translate-x-[300%]"
  defp translate_full(4), do: "-translate-x-[400%]"
  defp translate_full(5), do: "-translate-x-[500%]"
  defp translate_full(6), do: "-translate-x-[600%]"
  defp translate_full(7), do: "-translate-x-[700%]"
  defp translate_full(8), do: "-translate-x-[800%]"
  defp translate_full(9), do: "-translate-x-[900%]"
end
