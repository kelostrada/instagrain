defmodule InstagrainWeb.PostLive.FormComponent do
  use InstagrainWeb, :live_component

  import InstagrainWeb.PostComponents
  import InstagrainWeb.UserComponents

  alias Instagrain.Feed
  alias Instagrain.Feed.Post
  alias InstagrainWeb.ImageFilters

  @impl true
  def render(assigns) do
    assigns = assign(assigns, step: current_step(assigns))

    ~H"""
    <form
      id="post-form"
      phx-target={@myself}
      phx-change="validate"
      phx-submit="save"
      phx-drop-target={@uploads.file.ref}
      class={cond do
        @step == :edit -> "wide-modal edit-step"
        @step == :final -> "wide-modal"
        true -> "square-modal"
      end}
    >
      <.live_file_input id="post-form-upload" upload={@uploads.file} class="hidden" />

      <div class="flex flex-col h-full divide-y divide-solid divide-neutral-300">
        <div class="flex items-center">
          <%= if @step != :create do %>
            <div class="flex-1 cursor-pointer text-left pl-4" phx-click="back" phx-target={@myself}>
              <.icon name="hero-arrow-left" class="h-6 w-6" />
            </div>
          <% end %>
          <div class="grow text-center font-bold text-base leading-10 py-px">
            <%= step_to_title(@step) %>
          </div>
          <%= if @step in [:preview, :edit] do %>
            <div
              class="flex-1 cursor-pointer text-right font-bold text-sm text-sky-500 leading-10 pr-4"
              phx-click="next-step"
              phx-target={@myself}
            >
              Next
            </div>
          <% end %>
          <%= if @step == :final do %>
            <button
              class="flex-1 cursor-pointer text-right font-bold text-sm text-sky-500 leading-10 pr-4 disabled:text-neutral-400"
              phx-disable-with="Saving..."
              disabled={@form.errors != []}
            >
              Share
            </button>
          <% end %>
        </div>

        <div class={[
          "flex-auto flex min-h-0",
          if(@step == :edit, do: "max-sm:flex-col sm:divide-x sm:divide-solid sm:divide-neutral-300", else: "divide-x divide-solid divide-neutral-300")
        ]}>
          <%= if @step == :create do %>
            <div class="h-full w-full flex flex-col items-center justify-center">
              <.upload_icon />
              <p class="mb-2 text-xl font-normal py-3">Drag photos and videos here</p>
              <button
                class="px-4 py-1.5 font-semibold text-sm bg-brand text-white rounded-lg hover:bg-brand-dark focus:outline-none"
                id="post-form-select-files"
                phx-hook="TriggerClick"
                data-click-target={@uploads.file.ref}
              >
                Select From Computer
              </button>
            </div>
          <% end %>

          <%= if @step != :create do %>
            <div class={[
              "bg-neutral-50 relative overflow-hidden border-[0.5px] shadow-sm",
              if(@step == :final, do: "grow h-full max-sm:hidden"),
              if(@step == :edit, do: "max-sm:shrink-0 max-sm:grow max-sm:min-h-0 sm:grow sm:h-full"),
              if(@step not in [:edit, :final], do: "grow h-full")
            ]}>
              <div class={[
                "w-full h-full flex transition-transform duration-500 items-center",
                translate_full(@selected_item)
              ]}>
                <div
                  :for={entry <- @uploads.file.entries}
                  class="relative w-full h-full flex-shrink-0"
                >
                  <% settings = get_image_settings(@image_filters, entry.ref) %>
                  <div
                    class="w-full h-full"
                    style={if @step in [:edit, :final], do: ImageFilters.compute_filter_css(settings.filter, settings.adjustments)}
                  >
                    <.live_img_preview
                      entry={entry}
                      id={"preview-#{entry.ref}"}
                      class="w-full h-full object-contain"
                    />
                  </div>

                  <div
                    :if={@step in [:edit, :final] && ImageFilters.vignette_style(settings.adjustments)}
                    class="absolute inset-0 pointer-events-none"
                    style={ImageFilters.vignette_style(settings.adjustments)}
                  />

                  <button
                    :if={@step == :preview}
                    type="button"
                    phx-click="cancel-upload"
                    phx-value-ref={entry.ref}
                    phx-target={@myself}
                    aria-label="cancel"
                    class="absolute top-6 right-6"
                  >
                    &times;
                  </button>
                </div>
              </div>

              <% entries_len = length(@uploads.file.entries) %>

              <div
                :if={entries_len > 1 && @selected_item > 0}
                phx-click="previous-item"
                phx-target={@myself}
                class={[
                  "rounded-full cursor-pointer w-8 h-8 m-2",
                  "flex items-center justify-center",
                  "absolute left-0 top-1/2 translate-y-[-50%]",
                  "bg-neutral-900/80 hover:bg-neutral-900/50",
                  "transition ease-in-out duration-300"
                ]}
              >
                <.left_chevron_icon class="text-white" />
              </div>

              <div
                :if={entries_len > 1 && @selected_item < entries_len - 1}
                phx-click="next-item"
                phx-target={@myself}
                class={[
                  "rounded-full cursor-pointer w-8 h-8 m-2",
                  "flex items-center justify-center",
                  "absolute right-0 top-1/2 translate-y-[-50%]",
                  "bg-neutral-900/80 hover:bg-neutral-900/50",
                  "transition ease-in-out duration-300"
                ]}
              >
                <.right_chevron_icon class="text-white" />
              </div>
            </div>

            <%= if @step == :edit do %>
              <% current_entry = Enum.at(@uploads.file.entries, @selected_item) %>
              <% current_settings = get_image_settings(@image_filters, current_entry && current_entry.ref) %>

              <div class="max-sm:min-h-0 max-sm:shrink sm:flex-none sm:w-85 overflow-auto flex flex-col">
                <%!-- Tab bar --%>
                <div class="flex border-b border-neutral-200 shrink-0">
                  <button
                    type="button"
                    phx-click="edit-tab"
                    phx-value-tab="filters"
                    phx-target={@myself}
                    class={"flex-1 py-3 text-center font-semibold text-sm border-b #{if @edit_tab == :filters, do: "text-black border-black", else: "text-neutral-400 border-transparent"}"}
                  >
                    Filters
                  </button>
                  <button
                    type="button"
                    phx-click="edit-tab"
                    phx-value-tab="adjustments"
                    phx-target={@myself}
                    class={"flex-1 py-3 text-center font-semibold text-sm border-b #{if @edit_tab == :adjustments, do: "text-black border-black", else: "text-neutral-400 border-transparent"}"}
                  >
                    Adjustments
                  </button>
                </div>

                <%= if @edit_tab == :filters do %>
                  <%!-- Mobile: horizontal scrollable strip --%>
                  <div class="sm:hidden flex overflow-x-auto gap-3 px-4 py-3 scrollbar-hide">
                    <div
                      :for={{filter_id, filter_name} <- ImageFilters.filters()}
                      phx-click="select-filter"
                      phx-value-filter={filter_id}
                      phx-target={@myself}
                      class="cursor-pointer text-center flex-shrink-0"
                    >
                      <p class={"text-xs mb-1 #{if current_settings.filter == filter_id, do: "text-sky-500 font-semibold", else: "text-neutral-600"}"}>
                        <%= filter_name %>
                      </p>
                      <div
                        class={"w-[5.5rem] h-[5.5rem] overflow-hidden rounded-sm border-2 #{if current_settings.filter == filter_id, do: "border-sky-500", else: "border-transparent"}"}
                        style={ImageFilters.preset_style(filter_id)}
                      >
                        <.live_img_preview
                          :if={current_entry}
                          entry={current_entry}
                          id={"filter-thumb-mobile-#{filter_id}"}
                          class="w-full h-full object-cover"
                        />
                      </div>
                    </div>
                  </div>

                  <%!-- Desktop: 3-column grid --%>
                  <div class="max-sm:hidden grid grid-cols-3 gap-2 p-4 overflow-auto">
                    <div
                      :for={{filter_id, filter_name} <- ImageFilters.filters()}
                      phx-click="select-filter"
                      phx-value-filter={filter_id}
                      phx-target={@myself}
                      class="cursor-pointer text-center"
                    >
                      <div
                        class={"w-full aspect-square overflow-hidden rounded-sm border-2 #{if current_settings.filter == filter_id, do: "border-sky-500", else: "border-transparent"}"}
                        style={ImageFilters.preset_style(filter_id)}
                      >
                        <.live_img_preview
                          :if={current_entry}
                          entry={current_entry}
                          id={"filter-thumb-#{filter_id}"}
                          class="w-full h-full object-cover"
                        />
                      </div>
                      <p class={"text-xs mt-1 #{if current_settings.filter == filter_id, do: "text-sky-500 font-semibold", else: "text-neutral-600"}"}>
                        <%= filter_name %>
                      </p>
                    </div>
                  </div>
                <% end %>

                <%= if @edit_tab == :adjustments do %>
                  <div class="px-6 py-4 space-y-5 overflow-auto min-h-0 flex-1">
                    <div
                      :for={{key, label, min, max} <- ImageFilters.adjustment_options()}
                      class="space-y-1"
                    >
                      <div class="flex justify-between items-center">
                        <span class="font-semibold text-base"><%= label %></span>
                        <span class="text-neutral-500 text-base tabular-nums w-8 text-right">
                          <%= current_settings.adjustments[key] || 0 %>
                        </span>
                      </div>
                      <input
                        type="range"
                        min={min}
                        max={max}
                        value={current_settings.adjustments[key] || 0}
                        data-name={key}
                        phx-hook="AdjustmentSlider"
                        id={"adjustment-#{key}"}
                        class="w-full adjustment-slider"
                      />
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>

            <%= if @step == :final do %>
              <div class="flex-none max-sm:w-full md:w-85 overflow-auto">
                <div class="pt-4.5 pb-3.5">
                  <.user_post_header user={@current_user} current_user={@current_user} />
                </div>
                <div class="px-4">
                  <.input
                    type="textarea"
                    field={@form[:caption]}
                    placeholder="Write a caption..."
                    class={[
                      "block w-full h-40 p-0 border-0 outline-none outline-clear",
                      "resize-none placeholder:font-medium placeholder:text-neutral-350 text-black font-medium"
                    ]}
                  />
                </div>
                <div class="flex items-center justify-between border-b border-neutral-300">
                  <div class="p-2.5">
                    <.icon name="hero-face-smile" class="h-6 w-6 text-neutral-500" />
                  </div>
                  <div class="p-2.5">
                    <span class={"text-xs #{if @form[:caption].errors != [], do: "text-rose-600", else: "text-neutral-350"}"}>
                      <%= (@form[:caption].value || "")
                      |> String.length()
                      |> format_number() %> / 2,200
                    </span>
                  </div>
                </div>

                <div class="border-b border-neutral-300">
                  <div class="flex justify-between items-center py-[7px] px-4">
                    <div class="">
                      <.input
                        field={@form[:location]}
                        type="text"
                        placeholder="Add Location"
                        class={[
                          "block w-full h-7.5 p-0 border-0 outline-none outline-clear",
                          "placeholder:font-medium placeholder:text-neutral-500 text-black font-medium"
                        ]}
                      />
                    </div>
                    <div>
                      <.icon name="hero-map-pin" class="h-5 w-5 text-black" />
                    </div>
                  </div>

                  <details open={@tabs.accessibility} class="group font-medium px-4">
                    <summary
                      phx-click="tabs-click"
                      phx-target={@myself}
                      phx-value-tab={:accessibility}
                      class="py-2.5 flex cursor-pointer flex-row items-center justify-between group-open:font-bold text-black marker:[font-size:0px]"
                    >
                      Accessibility
                      <.icon
                        name="hero-chevron-down"
                        class="h-5 w-5 rotate-0 transform group-open:rotate-180"
                      />
                    </summary>
                    <div class="py-1">
                      <p class="text-neutral-500 text-xs font-normal">
                        Alt text describes your photos for people with visual impairments. Alt text will be automatically created for your photos or you can choose to write your own.
                      </p>

                      <%= for entry <- @uploads.file.entries do %>
                        <div class="my-3 flex">
                          <div class="w-11 h-11">
                            <.live_img_preview
                              id={"alts-#{entry.ref}"}
                              entry={entry}
                              class="w-full h-full object-cover"
                            />
                          </div>
                          <div class="ml-2 grow">
                            <.input
                              field={@form[:alts]}
                              multiple={true}
                              index={entry.ref}
                              type="text"
                              placeholder="Write alt text..."
                              class={[
                                "w-full py-[9px] placeholder:font-normal placeholder:text-sm placeholder:text-neutral-350 border-neutral-350 rounded-md",
                                "focus:border-zinc-400 focus:ring-0"
                              ]}
                            />
                          </div>
                        </div>
                      <% end %>
                    </div>
                  </details>

                  <details open={@tabs.advanced} class="group font-medium px-4">
                    <summary
                      phx-click="tabs-click"
                      phx-target={@myself}
                      phx-value-tab={:advanced}
                      class="py-2.5 flex cursor-pointer flex-row items-center justify-between group-open:font-bold text-black marker:[font-size:0px]"
                    >
                      Advanced Settings
                      <.icon
                        name="hero-chevron-down"
                        class="h-5 w-5 rotate-0 transform group-open:rotate-180"
                      />
                    </summary>
                    <div class="py-1">
                      <div class="flex items-center justify-between">
                        <span>Hide like and view counts on this post</span>
                        <.input field={@form[:hide_likes]} type="checkbox" />
                      </div>
                      <p class="py-2 text-neutral-500 text-xs font-normal">
                        Only you will see the total number of likes and views on this post. You can change this later by going to the ··· menu at the top of the post. To hide like counts on other people's posts, go to your account settings.
                      </p>
                    </div>
                    <div class="py-1">
                      <div class="flex items-center justify-between">
                        <span>Turn off commenting</span>
                        <.input field={@form[:disable_comments]} type="checkbox" />
                      </div>
                      <p class="py-2 text-neutral-500 text-xs font-normal">
                        You can change this later by going to the ··· menu at the top of your post.
                      </p>
                    </div>
                  </details>
                </div>

                <%!-- <.button phx-disable-with="Saving...">Save Post</.button> --%>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </form>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     assign(socket,
       previewed?: false,
       edited?: false,
       selected_item: 0,
       edit_tab: :filters,
       image_filters: %{},
       tabs: %{accessibility: false, advanced: false}
     )}
  end

  @impl true
  def update(%{current_user: current_user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Feed.change_post(%Post{}, %{user_id: current_user.id}))
     end)
     |> allow_upload(:file, accept: ~w(.jpg .jpeg .png .avi .mov .mpg .mp4 .webp), max_entries: 9)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    post_params = Map.put(post_params, "user_id", socket.assigns.current_user.id)
    changeset = Feed.change_post(%Post{}, post_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("next-step", _, socket) do
    case current_step(socket.assigns) do
      :preview -> {:noreply, assign(socket, previewed?: true)}
      :edit -> {:noreply, assign(socket, edited?: true)}
      _ -> {:noreply, socket}
    end
  end

  def handle_event("back", _, socket) do
    case current_step(socket.assigns) do
      :preview ->
        socket =
          Enum.reduce(socket.assigns.uploads.file.entries, socket, fn entry, socket ->
            cancel_upload(socket, :file, entry.ref)
          end)

        {:noreply, assign(socket, selected_item: 0, image_filters: %{})}

      :edit ->
        {:noreply, assign(socket, previewed?: false)}

      :final ->
        {:noreply, assign(socket, edited?: false)}
    end
  end

  def handle_event("next-item", _, socket) do
    {:noreply, assign(socket, selected_item: socket.assigns.selected_item + 1)}
  end

  def handle_event("previous-item", _, socket) do
    {:noreply, assign(socket, selected_item: socket.assigns.selected_item - 1)}
  end

  def handle_event("edit-tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, edit_tab: String.to_existing_atom(tab))}
  end

  def handle_event("select-filter", %{"filter" => filter}, socket) do
    entry = Enum.at(socket.assigns.uploads.file.entries, socket.assigns.selected_item)

    if entry do
      image_filters =
        Map.update(
          socket.assigns.image_filters,
          entry.ref,
          %{filter: filter, adjustments: ImageFilters.default_adjustments()},
          &%{&1 | filter: filter}
        )

      {:noreply, assign(socket, image_filters: image_filters)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("adjust", %{"name" => name, "value" => value}, socket) do
    entry = Enum.at(socket.assigns.uploads.file.entries, socket.assigns.selected_item)

    if entry do
      value = if is_integer(value), do: value, else: elem(Integer.parse(value), 0)

      image_filters =
        Map.update(
          socket.assigns.image_filters,
          entry.ref,
          %{filter: "original", adjustments: Map.put(ImageFilters.default_adjustments(), name, value)},
          fn settings ->
            %{settings | adjustments: Map.put(settings.adjustments, name, value)}
          end
        )

      {:noreply, assign(socket, image_filters: image_filters)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("tabs-click", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)
    {:noreply, assign(socket, tabs: Map.update!(socket.assigns.tabs, tab, &(!&1)))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    image_filters = socket.assigns.image_filters

    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        filename = Path.basename(path) <> Path.extname(entry.client_name)
        dest = Path.join([:code.priv_dir(:instagrain), "static", "uploads", filename])

        File.cp!(path, dest)

        settings =
          Map.get(image_filters, entry.ref, %{
            filter: "original",
            adjustments: ImageFilters.default_adjustments()
          })

        {:ok,
         %{
           filename: filename,
           entry: entry,
           filter: settings.filter,
           adjustments: settings.adjustments
         }}
      end)

    location_id = find_location(post_params["location"])

    post_params =
      post_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("location_id", location_id)

    with {:ok, post} <- Feed.create_post(post_params),
         {:ok, image} <- save_resources(post, post_params, uploaded_files),
         {:ok, _post} <- Feed.update_post(post, %{image: image}) do
      {:noreply,
       socket
       |> put_flash(:info, "Post created successfully")
       |> push_navigate(to: ~p"/p/#{post.id}")}
    else
      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Post creation failed")
         |> push_navigate(to: ~p"/")}
    end
  end

  defp find_location(_location) do
    1
  end

  defp save_resources(post, post_params, uploaded_files) do
    alts = post_params["alts"]

    Enum.reduce(uploaded_files, {:ok, ""}, fn
      file, {:ok, image} ->
        case Feed.create_resource(%{
               post_id: post.id,
               file: file.filename,
               type: :photo,
               alt: alts[file.entry.ref],
               filter: file.filter,
               adjustments: file.adjustments
             }) do
          {:ok, _resource} ->
            {:ok, if(image == "", do: file.filename, else: image)}

          {:error, error} ->
            {:error, error}
        end

      _file, {:error, error} ->
        {:error, error}
    end)
  end

  defp get_image_settings(image_filters, entry_ref) do
    Map.get(image_filters, entry_ref, %{
      filter: "original",
      adjustments: ImageFilters.default_adjustments()
    })
  end

  defp current_step(assigns) do
    case assigns do
      %{uploads: %{file: %{entries: []}}} -> :create
      %{previewed?: false} -> :preview
      %{edited?: false} -> :edit
      _ -> :final
    end
  end

  defp step_to_title(:create), do: "Create new post"
  defp step_to_title(:preview), do: "Preview"
  defp step_to_title(:edit), do: "Edit"
  defp step_to_title(:final), do: "Create new post"

  defp upload_icon(assigns) do
    ~H"""
    <svg
      aria-label="Icon to represent media such as images or videos"
      class="x1lliihq x1n2onr6 x5n08af"
      fill="currentColor"
      height="77"
      role="img"
      viewBox="0 0 97.6 77.3"
      width="96"
    >
      <title>Icon to represent media such as images or videos</title>
      <path
        d="M16.3 24h.3c2.8-.2 4.9-2.6 4.8-5.4-.2-2.8-2.6-4.9-5.4-4.8s-4.9 2.6-4.8 5.4c.1 2.7 2.4 4.8 5.1 4.8zm-2.4-7.2c.5-.6 1.3-1 2.1-1h.2c1.7 0 3.1 1.4 3.1 3.1 0 1.7-1.4 3.1-3.1 3.1-1.7 0-3.1-1.4-3.1-3.1 0-.8.3-1.5.8-2.1z"
        fill="currentColor"
      >
      </path>
      <path
        d="M84.7 18.4 58 16.9l-.2-3c-.3-5.7-5.2-10.1-11-9.8L12.9 6c-5.7.3-10.1 5.3-9.8 11L5 51v.8c.7 5.2 5.1 9.1 10.3 9.1h.6l21.7-1.2v.6c-.3 5.7 4 10.7 9.8 11l34 2h.6c5.5 0 10.1-4.3 10.4-9.8l2-34c.4-5.8-4-10.7-9.7-11.1zM7.2 10.8C8.7 9.1 10.8 8.1 13 8l34-1.9c4.6-.3 8.6 3.3 8.9 7.9l.2 2.8-5.3-.3c-5.7-.3-10.7 4-11 9.8l-.6 9.5-9.5 10.7c-.2.3-.6.4-1 .5-.4 0-.7-.1-1-.4l-7.8-7c-1.4-1.3-3.5-1.1-4.8.3L7 49 5.2 17c-.2-2.3.6-4.5 2-6.2zm8.7 48c-4.3.2-8.1-2.8-8.8-7.1l9.4-10.5c.2-.3.6-.4 1-.5.4 0 .7.1 1 .4l7.8 7c.7.6 1.6.9 2.5.9.9 0 1.7-.5 2.3-1.1l7.8-8.8-1.1 18.6-21.9 1.1zm76.5-29.5-2 34c-.3 4.6-4.3 8.2-8.9 7.9l-34-2c-4.6-.3-8.2-4.3-7.9-8.9l2-34c.3-4.4 3.9-7.9 8.4-7.9h.5l34 2c4.7.3 8.2 4.3 7.9 8.9z"
        fill="currentColor"
      >
      </path>
      <path
        d="M78.2 41.6 61.3 30.5c-2.1-1.4-4.9-.8-6.2 1.3-.4.7-.7 1.4-.7 2.2l-1.2 20.1c-.1 2.5 1.7 4.6 4.2 4.8h.3c.7 0 1.4-.2 2-.5l18-9c2.2-1.1 3.1-3.8 2-6-.4-.7-.9-1.3-1.5-1.8zm-1.4 6-18 9c-.4.2-.8.3-1.3.3-.4 0-.9-.2-1.2-.4-.7-.5-1.2-1.3-1.1-2.2l1.2-20.1c.1-.9.6-1.7 1.4-2.1.8-.4 1.7-.3 2.5.1L77 43.3c1.2.8 1.5 2.3.7 3.4-.2.4-.5.7-.9.9z"
        fill="currentColor"
      >
      </path>
    </svg>
    """
  end

  def right_chevron_icon(assigns) do
    ~H"""
    <svg
      aria-label="Right chevron"
      class={@class}
      fill="currentColor"
      height="16"
      role="img"
      viewBox="0 0 24 24"
      width="16"
    >
      <title>Right chevron</title>
      <polyline
        fill="none"
        points="8 3 17.004 12 8 21"
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
      >
      </polyline>
    </svg>
    """
  end

  def left_chevron_icon(assigns) do
    ~H"""
    <svg
      aria-label="Left chevron"
      class={@class}
      fill="currentColor"
      height="16"
      role="img"
      viewBox="0 0 24 24"
      width="16"
    >
      <title>Left chevron</title>
      <polyline
        fill="none"
        points="16.502 3 7.498 12 16.502 21"
        stroke="currentColor"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
      >
      </polyline>
    </svg>
    """
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
