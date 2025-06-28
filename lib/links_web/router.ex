defmodule LinksWeb.Router do
  use LinksWeb, :router

  import LinksWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LinksWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LinksWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [{LinksWeb.UserAuth, :mount_current_scope}] do
      live "/", HomeLive
      live "/posts/:id/comments", CommentsLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", LinksWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:links, :dev_routes) do

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LinksWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LinksWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end


  end

  scope "/", LinksWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{LinksWeb.UserAuth, :mount_current_scope}] do
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
