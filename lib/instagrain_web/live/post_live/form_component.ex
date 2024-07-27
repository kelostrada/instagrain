defmodule InstagrainWeb.PostLive.FormComponent do
  use InstagrainWeb, :live_component

  alias Instagrain.Feed

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
      class="h-full w-full"
    >
      <div class="flex flex-col h-full divide-y divide-solid">
        <div class="flex justify-between items-center">
          <%= if @step != :create do %>
            <div class="flex-1 cursor-pointer text-left pl-4" phx-click="back" phx-target={@myself}>
              <.icon name="hero-arrow-left" class="h-6 w-6" />
            </div>
          <% end %>
          <div class="flex-1 text-center font-bold text-base leading-10 py-px">
            <%= step_to_title(@step) %>
          </div>
          <%= if @step == :preview do %>
            <div
              class="flex-1 cursor-pointer text-right font-bold text-sm text-sky-500 leading-10 pr-4"
              phx-click="next_step"
              phx-target={@myself}
            >
              Next
            </div>
          <% end %>
          <%= if @step == :final do %>
            <button class="flex-1 cursor-pointer text-right font-bold text-sm text-sky-500 leading-10 pr-4">
              Share
            </button>
          <% end %>
        </div>

        <div class="flex-auto flex flex-col items-center justify-center">
          <.live_file_input id="post-form-upload" upload={@uploads.file} class="hidden" />

          <%= if @step == :create do %>
            <div class="flex flex-col items-center justify-center h-full">
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

          <%= if @step == :preview do %>
            <%= for entry <- @uploads.file.entries do %>
              <article class="upload-entry">
                <figure>
                  <.live_img_preview entry={entry} />
                  <figcaption><%= entry.client_name %></figcaption>
                </figure>

                <%!-- entry.progress will update automatically for in-flight entries --%>
                <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

                <%!-- a regular click event whose handler will invoke Phoenix.LiveView.cancel_upload/3 --%>
                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  aria-label="cancel"
                >
                  &times;
                </button>

                <%!-- Phoenix.Component.upload_errors/2 returns a list of error atoms --%>
                <%= for err <- upload_errors(@uploads.file, entry) do %>
                  <p class="alert alert-danger"><%= error_to_string(err) %></p>
                <% end %>
              </article>
            <% end %>
          <% end %>

          <%= if @step == :final do %>
            <.input field={@form[:caption]} type="text" label="Caption" />
            <.input field={@form[:location_id]} type="number" label="Location" />
            <.input field={@form[:hide_likes]} type="checkbox" label="Hide likes" />
            <.input field={@form[:disable_comments]} type="checkbox" label="Disable comments" />
            <.button phx-disable-with="Saving...">Save Post</.button>
          <% end %>
        </div>
      </div>
    </form>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket, previewed?: false)}
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Feed.change_post(post))
     end)
     |> allow_upload(:file, accept: ~w(.jpg .jpeg .png .avi .mov .mpg .mp4), max_entries: 9)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset = Feed.change_post(socket.assigns.post, post_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("next_step", _, socket) do
    {:noreply, assign(socket, previewed?: true)}
  end

  def handle_event("back", _, socket) do
    case current_step(socket.assigns) do
      :preview ->
        socket =
          Enum.reduce(socket.assigns.uploads.file.entries, socket, fn entry, socket ->
            cancel_upload(socket, :file, entry.ref)
          end)

        {:noreply, socket}

      :final ->
        {:noreply, assign(socket, previewed?: false)}
    end
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        filename = Path.basename(path) <> Path.extname(entry.client_name)
        dest = Path.join([:code.priv_dir(:instagrain), "static", "uploads", filename])

        File.cp!(path, dest)

        {:ok,
         %{
           filename: filename,
           entry: entry
         }}
      end)

    save_post(socket, socket.assigns.action, post_params, uploaded_files)
  end

  # ~p"/uploads/#{filename}"

  defp save_post(socket, :edit, post_params, _uploaded_files) do
    post_params = Map.put(post_params, "user_id", socket.assigns.user.id)

    case Feed.update_post(socket.assigns.post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :new, post_params, _uploaded_files) do
    post_params = Map.put(post_params, "user_id", socket.assigns.user.id)

    case Feed.create_post(post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp current_step(assigns) do
    case assigns do
      %{uploads: %{file: %{entries: []}}} -> :create
      %{previewed?: false} -> :preview
      _ -> :final
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp step_to_title(:create), do: "Create new post"
  defp step_to_title(:preview), do: "Preview"
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
end
