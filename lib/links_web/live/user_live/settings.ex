defmodule LinksWeb.UserLive.Settings do
  use LinksWeb, :live_view

  alias Links.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-8">
        <!-- Username Update Section -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Update Username</h2>

          <.form
            for={@username_form}
            id="username_form"
            phx-submit="update_username"
            phx-change="validate_username"
          >
            <div class="form-control">
              <p class="label block mb-2">
                <span class="label-text">Username</span>
              </p>
              <div class="join">
                <input
                  name={@username_form[:username].name}
                  value={@username_form[:username].value}
                  type="text"
                  placeholder="Enter new username"
                  autocomplete="username"
                  class="input min-w-xs join-item"
                  required
                />
                <button type="submit" class="btn btn-primary join-item" phx-disable-with="Updating...">
                  Update Username
                </button>
              </div>

              <%= if @username_form[:username].errors != [] do %>
                <div class="text-red-600 text-sm mt-1">
                  <%= for {msg, _} <- @username_form[:username].errors do %>
                    <p>{msg}</p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </.form>
        </div>
        
    <!-- Email Update Section -->
        <div>
          <h2 class="text-xl font-semibold text-gray-900 mb-4">Update Email</h2>

          <.form
            for={@email_form}
            id="email_form"
            phx-submit="update_email"
            phx-change="validate_email"
          >
            <div class="form-control">
              <p class="label block mb-2">
                <span class="label-text">Email</span>
              </p>
              <div class="join">
                <input
                  name={@email_form[:email].name}
                  value={@email_form[:email].value}
                  type="email"
                  placeholder="Enter new email"
                  autocomplete="username"
                  class="input min-w-xs join-item"
                  required
                />
                <button type="submit" class="btn btn-primary join-item" phx-disable-with="Changing...">
                  Update Email
                </button>
              </div>

              <%= if @email_form[:email].errors != [] do %>
                <div class="text-red-600 text-sm mt-1">
                  <%= for {msg, _} <- @email_form[:email].errors do %>
                    <p>{msg}</p>
                  <% end %>
                </div>
              <% end %>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_scope.user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    email_changeset = Accounts.change_user_email(user, %{}, validate_email: false)
    username_changeset = Accounts.change_user_username(user, %{}, validate_username: false)

    socket =
      socket
      |> assign(:current_email, user.email)
      |> assign(:current_username, user.username)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:page_title, "Settings")

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"user" => user_params} = params

    email_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_email(user_params, validate_email: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form)}
  end

  def handle_event("validate_username", params, socket) do
    %{"user" => user_params} = params

    username_form =
      socket.assigns.current_scope.user
      |> Accounts.change_user_username(user_params, validate_username: false)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, username_form: username_form)}
  end

  def handle_event("update_username", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    case Accounts.update_user_username(user, user_params) do
      {:ok, updated_user} ->
        # Update the current_scope with the new user data
        updated_scope = Links.Accounts.Scope.for_user(updated_user)

        info = "Username updated successfully to @#{updated_user.username}!"

        {:noreply,
         socket
         |> assign(:current_scope, updated_scope)
         |> put_flash(:info, info)
         |> assign(:current_username, updated_user.username)
         |> assign(
           :username_form,
           to_form(Accounts.change_user_username(updated_user, %{}, validate_username: false))
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :username_form, to_form(changeset, action: :insert))}
    end
  end

  def handle_event("update_email", params, socket) do
    %{"user" => user_params} = params
    user = socket.assigns.current_scope.user

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/settings/confirm-email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info)}

      changeset ->
        {:noreply, assign(socket, :email_form, to_form(changeset, action: :insert))}
    end
  end
end
