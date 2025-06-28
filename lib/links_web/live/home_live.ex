defmodule LinksWeb.HomeLive do
  use LinksWeb, :live_view

  alias Links.Posts

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:posts, Posts.list_posts_by_points()) |> assign(:page_title, "Home")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto px-4 py-6">
      <header class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900 mb-2">Links</h1>
        <p class="text-gray-600">A community-driven link aggregator.</p>
      </header>

      <div class="space-y-4">
        <%= for post <- @posts do %>
          <article class="flex items-start space-x-4 p-4 bg-white rounded-lg border border-gray-200 hover:border-gray-300 transition-colors">
            <div class="flex flex-col items-center space-y-1 min-w-0">
              <button class="text-gray-400 hover:text-orange-500 transition-colors">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                    clip-rule="evenodd"
                  >
                  </path>
                </svg>
              </button>
              <span class="text-sm font-medium text-gray-900">{post.points}</span>
              <button class="text-gray-400 hover:text-orange-500 transition-colors">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path
                    fill-rule="evenodd"
                    d="M10 17a1 1 0 01-1-1v-5H4a1 1 0 110-2h5V4a1 1 0 112 0v5h5a1 1 0 110 2h-5v5a1 1 0 01-1 1z"
                    clip-rule="evenodd"
                    transform="rotate(180 10 10)"
                  >
                  </path>
                </svg>
              </button>
            </div>

            <div class="flex-1 min-w-0">
              <div class="flex items-start justify-between">
                <div class="flex-1 min-w-0">
                  <h3 class="text-lg font-medium text-gray-900 hover:text-blue-600 transition-colors">
                    <a href={post.url} target="_blank" rel="noopener noreferrer" class="block">
                      {post.title}
                      <span class="text-sm text-gray-500 ml-2">({extract_domain(post.url)})</span>
                    </a>
                  </h3>

                  <div class="mt-2 flex items-center space-x-4 text-sm text-gray-500">
                    <span>by {post.author}</span>
                    <span>{format_time_ago(post.inserted_at)}</span>
                    <.link
                      navigate={~p"/posts/#{post.id}/comments"}
                      class="hover:text-gray-700 transition-colors"
                    >
                      {post.comment_count} comments
                    </.link>
                    <div class="flex space-x-2">
                      <%= for tag <- post.tags do %>
                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                          {tag}
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </article>
        <% end %>
      </div>
    </div>
    """
  end

  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> "unknown"
    end
  end

  defp format_time_ago(datetime) do
    now = DateTime.utc_now()

    # Convert NaiveDateTime to DateTime if needed
    datetime =
      case datetime do
        %DateTime{} = dt -> dt
        %NaiveDateTime{} = ndt -> DateTime.from_naive!(ndt, "Etc/UTC")
      end

    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end
end
