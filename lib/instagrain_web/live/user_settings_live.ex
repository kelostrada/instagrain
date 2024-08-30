defmodule InstagrainWeb.UserSettingsLive do
  use InstagrainWeb, :live_view

  alias Instagrain.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h2 class="text-xl font-extrabold mb-8">
        Edit Profile
      </h2>

      <div class="space-y-12 divide-y">
        <div>
          <form
            id="avatar-form"
            phx-change="validate_avatar"
            phx-submit="update_avatar"
            phx-drop-target={@uploads.avatar.ref}
            class="w-48 flex flex-col items-center justify-center gap-2 cursor-pointer"
          >
            <% entry = List.first(@uploads.avatar.entries) %>
            <.live_file_input id="avatar-form-upload" upload={@uploads.avatar} class="hidden" />
            <div
              id="avatar-container"
              class="w-48 h-48 rounded-full border-2"
              phx-hook="TriggerClick"
              data-click-target={@uploads.avatar.ref}
            >
              <.live_img_preview
                :if={!is_nil(entry)}
                entry={entry}
                id={"avatar-#{entry.ref}"}
                class="w-full h-full object-cover rounded-full"
              />
              <img
                :if={is_nil(entry) && !is_nil(@current_user.avatar)}
                src={~p"/uploads/avatars/#{@current_user.avatar}"}
                class="w-full h-full object-cover rounded-full"
              />
              <.icon
                :if={is_nil(entry) && is_nil(@current_user.avatar)}
                name="hero-user"
                class="h-full w-full rounded-full"
              />
            </div>
            <.button :if={@uploads.avatar.entries != []} type="submit">Update Avatar</.button>

            <%= if entry do %>
              <p
                :for={err <- Phoenix.Component.upload_errors(@uploads.avatar, entry)}
                class="alert alert-danger"
              >
                Error: <%= err %>
              </p>
            <% end %>
          </form>
        </div>

        <div>
          <.simple_form
            for={@username_form}
            id="username_form"
            phx-submit="update_username"
            phx-change="validate_username"
          >
            <.input field={@username_form[:username]} type="text" label="Username" required />
            <:actions>
              <.button phx-disable-with="Changing...">Change Username</.button>
            </:actions>
          </.simple_form>
        </div>
        <div>
          <.simple_form
            for={@profile_form}
            id="profile_form"
            phx-submit="update_profile"
            phx-change="validate_profile"
          >
            <.input field={@profile_form[:full_name]} type="text" label="Full name" required />
            <.input field={@profile_form[:description]} type="textarea" label="Bio" required />
            <:actions>
              <.button phx-disable-with="Changing...">Change profile data</.button>
            </:actions>
          </.simple_form>
        </div>
        <div>
          <.simple_form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <.input field={@email_form[:email]} type="email" label="Email" required />
            <.input
              field={@email_form[:current_password]}
              name="current_password"
              id="current_password_for_email"
              type="password"
              label="Current password"
              value={@email_form_current_password}
              required
            />
            <:actions>
              <.button phx-disable-with="Changing...">Change Email</.button>
            </:actions>
          </.simple_form>
        </div>
        <div>
          <.simple_form
            for={@password_form}
            id="password_form"
            action={~p"/users/log_in?_action=password_updated"}
            method="post"
            phx-change="validate_password"
            phx-submit="update_password"
            phx-trigger-action={@trigger_submit}
          >
            <input
              name={@password_form[:email].name}
              type="hidden"
              id="hidden_user_email"
              value={@current_email}
            />
            <.input field={@password_form[:password]} type="password" label="New password" required />
            <.input
              field={@password_form[:password_confirmation]}
              type="password"
              label="Confirm new password"
            />
            <.input
              field={@password_form[:current_password]}
              name="current_password"
              type="password"
              label="Current password"
              id="current_password_for_password"
              value={@current_password}
              required
            />
            <:actions>
              <.button phx-disable-with="Changing...">Change Password</.button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    username_changeset = Accounts.change_user_username(user)
    profile_changeset = Accounts.change_user_profile(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:current_username, user.username)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:trigger_submit, false)
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_username", params, socket) do
    %{"user" => user_params} = params

    username_form =
      socket.assigns.current_user
      |> Accounts.change_user_username(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, username_form: username_form)}
  end

  def handle_event("update_username", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_username(user, user_params) do
      {:ok, updated_user} ->
        info = "Username updated successfully."
        {:noreply, socket |> put_flash(:info, info) |> assign(:current_user, updated_user)}

      {:error, changeset} ->
        {:noreply, assign(socket, :username_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_avatar", _, socket) do
    {:noreply, socket}
  end

  def handle_event("update_avatar", _, socket) do
    socket
    |> consume_uploaded_entries(:avatar, fn %{path: path}, entry ->
      filename = Path.basename(path) <> Path.extname(entry.client_name)
      dest = Path.join([:code.priv_dir(:instagrain), "static", "uploads", "avatars", filename])

      File.cp!(path, dest)

      {:ok, filename}
    end)
    |> List.first()
    |> then(fn filename ->
      Accounts.update_user_avatar(socket.assigns.current_user, %{avatar: filename})
    end)
    |> case do
      {:ok, user} ->
        {:noreply, assign(socket, current_user: user)}

      {:error, _changeset} ->
        {:noreply, socket |> put_flash(:error, "Error uploading avatar")}
    end
  end

  def handle_event("validate_profile", params, socket) do
    %{"user" => user_params} = params

    profile_form =
      socket.assigns.current_user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("update_profile", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, updated_user} ->
        info = "Profile updated successfully."
        {:noreply, socket |> put_flash(:info, info) |> assign(:current_user, updated_user)}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end
