defmodule Links.Accounts.UserNotifier do
  import Swoosh.Email

  alias Links.Mailer
  alias Links.Accounts.User

  # Delivers the email using the application mailer with both HTML and text versions
  defp deliver(recipient, subject, html_content, text_content) do
    new()
    |> to(recipient)
    |> from({"Links", "links@myhren.ai"})
    |> subject(subject)
    |> html_body(html_content)
    |> text_body(text_content)
    |> Mailer.deliver()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    subject = "Update Your Email Address"

    html_content = """
    <html>
    <body>
      <h2>Update Your Email Address</h2>
      <p>Hi there,</p>
      <p>You can change your email by clicking here: <a href="#{url}">Update Email Address</a></p>
      <hr>
      <small>This email was sent from Links.</small>
    </body>
    </html>
    """

    text_content = """
    Update Your Email Address

    Hi there,

    You can change your email by visiting this URL: #{url}

    ---
    This email was sent from Links.
    """

    deliver(user.email, subject, html_content, text_content)
  end

  @doc """
  Deliver instructions to login with a magic link.
  """
  def deliver_login_instructions(user, url) do
    subject =
      case user do
        %User{confirmed_at: nil} -> "Welcome! Login to Links"
        _ -> "Your Login Link"
      end

    html_content = """
    <html>
    <body>
      <h2>Login to Links</h2>
      <p>Hi there,</p>
      <p>You can login to your account by clicking here: <a href="#{url}">Login to Links</a></p>
      <hr>
      <small>This email was sent from Links.</small>
    </body>
    </html>
    """

    text_content = """
    Login to Links

    Hi there,

    You can login to your account by visiting this URL: #{url}

    ---
    This email was sent from Links.
    """

    deliver(user.email, subject, html_content, text_content)
  end
end
