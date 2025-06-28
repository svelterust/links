defmodule LinksWeb.UserSessionController do
  use LinksWeb, :controller

  alias Links.Accounts
  alias LinksWeb.UserAuth

  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # magic link login - always remember users
  defp create(conn, %{"user" => %{"token" => token} = user_params}, info) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, user, tokens_to_disconnect} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        # Always remember users by setting remember_me to true
        user_params_with_remember = Map.put(user_params, "remember_me", "true")

        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params_with_remember)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/login")
    end
  end



  def magic_link_login(conn, %{"token" => token}) do
    case Accounts.login_user_by_magic_link(token) do
      {:ok, user, tokens_to_disconnect} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, "You have been logged in!")
        |> UserAuth.log_in_user(user, %{"remember_me" => "true"})

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> UserAuth.log_out_user()
  end
end
