defmodule Mix.Tasks.GenLoginLink do
  @moduledoc """
  Generate a magic login link for a user.

  ## Examples

      $ mix gen_login_link alice@example.com
      Login link: http://localhost:4000/login/SFMyNTY...

  """
  @shortdoc "Generate a magic login link for a user"

  use Mix.Task

  alias Links.Accounts
  alias Links.Repo

  @impl Mix.Task
  def run([email]) do
    Mix.Task.run("app.start")

    case Accounts.get_user_by_email(email) do
      nil ->
        Mix.shell().error("User with email #{email} not found")
        Mix.shell().info("Available users:")
        
        Repo.all(Links.Accounts.User)
        |> Enum.each(fn user ->
          Mix.shell().info("  - #{user.email}")
        end)

      user ->
        {encoded_token, user_token} = Links.Accounts.UserToken.build_email_token(user, "login")
        Repo.insert!(user_token)
        
        url = "http://localhost:4000/login/#{encoded_token}"
        Mix.shell().info("Login link for #{email}:")
        Mix.shell().info(url)
    end
  end

  def run([]) do
    Mix.shell().error("Please provide an email address")
    Mix.shell().info("Usage: mix gen_login_link user@example.com")
    
    Mix.shell().info("Available users:")
    Mix.Task.run("app.start")
    
    Repo.all(Links.Accounts.User)
    |> Enum.each(fn user ->
      Mix.shell().info("  - #{user.email}")
    end)
  end

  def run(_) do
    Mix.shell().error("Please provide exactly one email address")
    Mix.shell().info("Usage: mix gen_login_link user@example.com")
  end
end