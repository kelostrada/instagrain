defmodule InstagrainWeb.PostLive.EditFormComponent do
  @moduledoc """
  Modal for editing an existing post. Mirrors the :final step of the
  new-post flow: caption, location, accessibility alts, hide-like-count,
  disable-comments. Image uploads and filter editing are not supported
  here — owners toggle filters when first uploading the post.
  """

  use InstagrainWeb, :live_component

  import InstagrainWeb.UserComponents

  alias Instagrain.Feed
  alias InstagrainWeb.ImageFilters

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       location_results: [],
       selected_location: nil,
       tabs: %{accessibility: false, advanced: false}
     )}
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset =
      Feed.change_post(post, %{
        "caption" => post.caption,
        "hide_likes" => post.hide_likes,
        "disable_comments" => post.disable_comments,
        "alts" => alts_map(post)
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       form: to_form(changeset),
       selected_location: post.location && Map.from_struct(post.location)
     )}
  end

  defp alts_map(post) do
    post.resources
    |> Enum.with_index()
    |> Enum.into(%{}, fn {r, i} -> {"r#{i}", r.alt || ""} end)
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset = Feed.change_post(socket.assigns.post, post_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("location-search", %{"value" => query}, socket) do
    results = if String.length(query) >= 2, do: Feed.search_locations(query), else: []
    {:noreply, assign(socket, location_results: results, selected_location: nil)}
  end

  def handle_event("select-location", params, socket) do
    location = %{
      name: params["name"],
      address: params["address"],
      lat: parse_float(params["lat"]),
      lng: parse_float(params["lng"])
    }

    {:noreply, assign(socket, selected_location: location, location_results: [])}
  end

  def handle_event("clear-location", _, socket) do
    {:noreply, assign(socket, selected_location: nil, location_results: [])}
  end

  def handle_event("tabs-click", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)
    {:noreply, assign(socket, tabs: Map.update!(socket.assigns.tabs, tab, &(!&1)))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    alts = Map.get(post_params, "alts", %{})

    location_id =
      case socket.assigns.selected_location do
        %{name: name} = loc when is_binary(name) and name != "" ->
          case Feed.find_or_create_location(loc) do
            {:ok, %{id: id}} -> id
            _ -> nil
          end

        _ ->
          nil
      end

    attrs =
      post_params
      |> Map.take(["caption", "hide_likes", "disable_comments"])
      |> Map.put("location_id", location_id)

    with {:ok, updated} <- Feed.update_post(socket.assigns.post, attrs),
         :ok <- update_resource_alts(socket.assigns.post, alts) do
      fresh = Feed.get_post!(updated.id, socket.assigns.current_user.id)
      send(self(), {__MODULE__, {:post_updated, fresh}})
      send(self(), {__MODULE__, :close})
      {:noreply, put_flash(socket, :info, "Post updated.") |> assign(post: fresh)}
    else
      _ ->
        {:noreply, put_flash(socket, :error, "Could not update post.")}
    end
  end

  defp update_resource_alts(post, alts) do
    post.resources
    |> Enum.with_index()
    |> Enum.each(fn {resource, i} ->
      new_alt = Map.get(alts, "r#{i}")
      if is_binary(new_alt) and new_alt != (resource.alt || "") do
        Feed.update_resource(resource, %{alt: new_alt})
      end
    end)

    :ok
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil
  defp parse_float(val) when is_float(val), do: val

  defp parse_float(val) when is_binary(val) do
    case Float.parse(val) do
      {f, _} -> f
      :error -> nil
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <form
      id={"edit-post-form-#{@post.id}"}
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save"
      class="wide-modal"
    >
      <div class="flex flex-col h-full divide-y divide-solid divide-neutral-300">
        <div class="flex items-center">
          <div class="flex-1"></div>
          <div class="grow text-center font-bold text-base leading-10 py-px">Edit info</div>
          <button
            type="submit"
            class="flex-1 text-right font-bold text-sm text-sky-500 leading-10 pr-4 disabled:text-neutral-400"
            phx-disable-with="Saving..."
            disabled={@form.errors != []}
          >
            Done
          </button>
        </div>

        <div class="flex-auto flex min-h-0 divide-x divide-solid divide-neutral-300">
          <div class="bg-neutral-50 max-sm:hidden grow h-full flex items-center justify-center overflow-hidden">
            <img
              :if={resource = List.first(@post.resources)}
              src={resource_url(resource, :medium)}
              class="w-full h-full object-contain"
              style={ImageFilters.resource_filter_style(resource)}
            />
          </div>

          <div class="w-full sm:w-[340px] flex flex-col overflow-y-auto">
            <div class="p-3 flex gap-2 items-center">
              <.avatar user={@current_user} size={:sm} />
              <.username user={@current_user} />
            </div>

            <div class="px-3 pb-3">
              <textarea
                id={"edit-caption-#{@post.id}"}
                name="post[caption]"
                rows="4"
                maxlength="2200"
                class="w-full outline-none resize-none text-sm border-0 focus:ring-0 p-0"
                placeholder="Write a caption..."
              ><%= Phoenix.HTML.Form.input_value(@form, :caption) %></textarea>
              <div class="flex justify-between text-xs text-neutral-400 mt-1">
                <span>
                  <%= String.length(Phoenix.HTML.Form.input_value(@form, :caption) || "") %>/2,200
                </span>
              </div>
            </div>

            <hr />

            <div class="px-3 py-3 relative">
              <%= if @selected_location do %>
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-2 text-sm truncate">
                    <.icon name="hero-map-pin" class="w-4 h-4" />
                    <span class="truncate"><%= @selected_location.name %></span>
                  </div>
                  <button
                    type="button"
                    phx-click="clear-location"
                    phx-target={@myself}
                    class="text-neutral-400 hover:text-neutral-600"
                  >
                    <.icon name="hero-x-mark" class="w-4 h-4" />
                  </button>
                </div>
              <% else %>
                <input
                  type="text"
                  phx-keyup="location-search"
                  phx-debounce="300"
                  phx-target={@myself}
                  placeholder="Add location"
                  class="w-full text-sm border-0 focus:ring-0 p-0"
                />
                <ul
                  :if={@location_results != []}
                  class="absolute left-0 right-0 bg-white border border-neutral-200 z-10 max-h-60 overflow-y-auto"
                >
                  <li
                    :for={loc <- @location_results}
                    phx-click="select-location"
                    phx-target={@myself}
                    phx-value-name={loc.name}
                    phx-value-address={loc.address}
                    phx-value-lat={loc.lat}
                    phx-value-lng={loc.lng}
                    class="px-3 py-2 text-sm hover:bg-neutral-50 cursor-pointer"
                  >
                    <div class="font-medium"><%= loc.name %></div>
                    <div :if={loc.address} class="text-xs text-neutral-500 truncate">
                      <%= loc.address %>
                    </div>
                  </li>
                </ul>
              <% end %>
            </div>

            <hr />

            <div class="px-3 py-3">
              <button
                type="button"
                phx-click="tabs-click"
                phx-value-tab="accessibility"
                phx-target={@myself}
                class="flex items-center justify-between w-full text-sm"
              >
                Accessibility
                <.icon
                  name={if @tabs.accessibility, do: "hero-chevron-up", else: "hero-chevron-down"}
                  class="w-4 h-4"
                />
              </button>

              <div :if={@tabs.accessibility} class="mt-2 space-y-2">
                <p class="text-xs text-neutral-500 leading-snug">
                  Alt text describes your photos for people with visual impairments.
                </p>
                <div
                  :for={{resource, i} <- Enum.with_index(@post.resources)}
                  class="flex gap-2 items-start"
                >
                  <img
                    src={resource_url(resource, :thumb)}
                    class="w-10 h-10 object-cover rounded"
                    style={ImageFilters.resource_filter_style(resource)}
                  />
                  <input
                    type="text"
                    name={"post[alts][r#{i}]"}
                    value={resource.alt || ""}
                    placeholder="Write alt text..."
                    class="flex-1 text-sm border border-neutral-200 rounded px-2 py-1 focus:ring-0 focus:border-neutral-400"
                  />
                </div>
              </div>
            </div>

            <hr />

            <div class="px-3 py-3">
              <button
                type="button"
                phx-click="tabs-click"
                phx-value-tab="advanced"
                phx-target={@myself}
                class="flex items-center justify-between w-full text-sm"
              >
                Advanced settings
                <.icon
                  name={if @tabs.advanced, do: "hero-chevron-up", else: "hero-chevron-down"}
                  class="w-4 h-4"
                />
              </button>

              <div :if={@tabs.advanced} class="mt-3 space-y-3">
                <label class="flex items-start gap-2 text-sm">
                  <input
                    type="hidden"
                    name="post[hide_likes]"
                    value="false"
                  />
                  <input
                    type="checkbox"
                    name="post[hide_likes]"
                    value="true"
                    checked={Phoenix.HTML.Form.input_value(@form, :hide_likes) == true}
                    class="mt-0.5"
                  />
                  <span>
                    <span class="block">Hide like count on this post</span>
                    <span class="text-xs text-neutral-500">
                      Only you will see the total number of likes on this post.
                    </span>
                  </span>
                </label>

                <label class="flex items-start gap-2 text-sm">
                  <input
                    type="hidden"
                    name="post[disable_comments]"
                    value="false"
                  />
                  <input
                    type="checkbox"
                    name="post[disable_comments]"
                    value="true"
                    checked={Phoenix.HTML.Form.input_value(@form, :disable_comments) == true}
                    class="mt-0.5"
                  />
                  <span>
                    <span class="block">Turn off commenting</span>
                    <span class="text-xs text-neutral-500">
                      You can change this later by going to the post options.
                    </span>
                  </span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>
    </form>
    """
  end
end
