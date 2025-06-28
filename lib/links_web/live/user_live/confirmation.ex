defmodule LinksWeb.UserLive.Confirmation do
  use LinksWeb, :live_view

  alias Links.Accounts

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-sm mx-auto">
        <div class="card bg-base-100 shadow-lg border border-base-200">
          <div class="card-body text-center">
            <div class="w-12 h-12 bg-success/20 rounded-full flex items-center justify-center mx-auto mb-3">
              <.icon name="hero-check" class="w-6 h-6 text-success" />
            </div>
            <h2 class="card-title justify-center mb-1">Welcome!</h2>
            <p class="text-base-content/70 text-sm mb-4">Click below to complete your login</p>

            <.form
              :if={!@user.confirmed_at}
              for={@form}
              id="confirmation_form"
              phx-submit="submit"
              action={~p"/users/log-in?_action=confirmed"}
              phx-trigger-action={@trigger_submit}
            >
              <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
              <input type="hidden" name={@form[:remember_me].name} value="true" />
              
              <.button phx-disable-with="Confirming..." class="btn btn-primary w-full">
                Confirm my account
              </.button>
            </.form>

            <.form
              :if={@user.confirmed_at}
              for={@form}
              id="login_form"
              phx-submit="submit"
              action={~p"/users/log-in"}
              phx-trigger-action={@trigger_submit}
            >
              <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
              <input type="hidden" name={@form[:remember_me].name} value="true" />
              
              <.button phx-disable-with="Logging in..." class="btn btn-primary w-full">
                Continue to Links
              </.button>
            </.form>

            <p class="text-base-content/50 text-xs mt-4">
              You'll stay logged in on this device
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = to_form(%{"token" => token}, as: "user")

      {:ok, assign(socket, user: user, form: form, trigger_submit: false),
       temporary_assigns: [form: nil]}
    else
      {:ok,
       socket
       |> put_flash(:error, "Magic link is invalid or it has expired.")
       |> push_navigate(to: ~p"/users/log-in")}
    end
  end

  def handle_event("submit", %{"user" => params}, socket) do
    {:noreply, assign(socket, form: to_form(params, as: "user"), trigger_submit: true)}
  end
end
