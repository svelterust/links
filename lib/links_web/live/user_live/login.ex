defmodule LinksWeb.UserLive.Login do
  use LinksWeb, :live_view

  alias Links.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>

    <%= if @login_sent do %>
        <p class="text-gray-600">
          A magic link has been sent to your email address. Check your inbox and click the link to login.
        </p>
    <% else %>
      <p class="text-gray-600 mb-4">
        Login with your email address. If you don't have an account, it will automatically be created for you.
      </p>

      <.form
            :let={f}
            for={@form}
            id="login_form"
            action={~p"/login"}
            phx-submit="submit_magic"
          >
          <div class="form-control">
            <p class="label block mb-2">
              <span class="label-text">Email</span>
            </p>
            <div class="join">
              <input
                readonly={!!@current_scope}
                name={f[:email].name}
                value={f[:email].value}
                type="email"
                placeholder="Enter your email"
                autocomplete="email"
                phx-mounted={JS.focus()}
                class="input min-w-xs join-item"
                required
              />
              <button type="submit" class="btn btn-primary join-item">
                Login
              </button>
            </div>
          </div>
        </.form>
    <% end %>
  </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    email =
      Phoenix.Flash.get(socket.assigns.flash, :email) ||
        get_in(socket.assigns, [:current_scope, Access.key(:user), Access.key(:email)])

    form = to_form(%{"email" => email}, as: "user")

    {:ok, assign(socket, form: form, trigger_submit: false, login_sent: false) |> assign(:page_title, "Login")}
  end

  def handle_event("submit_magic", %{"user" => %{"email" => email}}, socket) do
    # Get existing user or create new one
    user = case Accounts.get_user_by_email(email) do
      nil ->
        # Create new user
        case Accounts.register_user(%{"email" => email}) do
          {:ok, user} -> user
          {:error, _changeset} -> nil
        end
      existing_user -> existing_user
    end

    if user do
      Accounts.deliver_login_instructions(
        user,
        &url(~p"/login/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(:info, "We've sent you a magic link to login. Check your email!")
     |> assign(:login_sent, true)}
  end

  defp local_mail_adapter? do
    Application.get_env(:links, Links.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
