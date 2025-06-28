# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Links.Repo.insert!(%Links.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Links.Repo
alias Links.Posts.Post
alias Links.Posts.Comment

# Clear existing data
Repo.delete_all(Comment)
Repo.delete_all(Post)

# Create posts using Repo.insert! directly
post1 = Repo.insert!(%Post{
  title: "Phoenix LiveView 1.0 Released",
  url: "https://phoenixframework.org/blog/phoenix-liveview-1-0-released",
  author: "chrismccord",
  points: 234,
  comment_count: 3,
  tags: ["elixir", "phoenix", "web"]
})

post2 = Repo.insert!(%Post{
  title: "Building Real-time Applications with Elixir and Phoenix",
  url: "https://example.com/realtime-elixir",
  author: "josevalim",
  points: 189,
  comment_count: 2,
  tags: ["elixir", "real-time"]
})

post3 = Repo.insert!(%Post{
  title: "The Future of Functional Programming",
  url: "https://example.com/functional-programming-future",
  author: "functional_fan",
  points: 156,
  comment_count: 1,
  tags: ["programming", "functional"]
})

post4 = Repo.insert!(%Post{
  title: "Distributed Systems in Elixir: A Complete Guide",
  url: "https://example.com/distributed-elixir",
  author: "distributed_dev",
  points: 298,
  comment_count: 1,
  tags: ["elixir", "distributed", "guide"]
})

post5 = Repo.insert!(%Post{
  title: "Why I Chose Elixir for My Startup",
  url: "https://example.com/elixir-startup",
  author: "startup_founder",
  points: 142,
  comment_count: 1,
  tags: ["elixir", "startup", "business"]
})

post6 = Repo.insert!(%Post{
  title: "GenServer Patterns and Best Practices",
  url: "https://example.com/genserver-patterns",
  author: "elixir_expert",
  points: 178,
  comment_count: 1,
  tags: ["elixir", "genserver", "patterns"]
})

post7 = Repo.insert!(%Post{
  title: "Building a Link Aggregator with Phoenix LiveView",
  url: "https://example.com/link-aggregator-liveview",
  author: "phoenix_dev",
  points: 201,
  comment_count: 1,
  tags: ["phoenix", "liveview", "tutorial"]
})

post8 = Repo.insert!(%Post{
  title: "Elixir Performance Tips and Tricks",
  url: "https://example.com/elixir-performance",
  author: "performance_guru",
  points: 267,
  comment_count: 1,
  tags: ["elixir", "performance", "optimization"]
})

# Create some comments
Repo.insert!(%Comment{
  content: "This is a great release! LiveView has been a game changer for Phoenix development.",
  author: "elixir_fan",
  link_id: post1.id
})

Repo.insert!(%Comment{
  content: "I've been using LiveView in production for months now. It's incredibly stable and fast.",
  author: "production_user",
  link_id: post1.id
})

Repo.insert!(%Comment{
  content: "The real-time capabilities are impressive. No more complex JavaScript for basic interactions.",
  author: "js_refugee",
  link_id: post1.id
})

Repo.insert!(%Comment{
  content: "Real-time features in Phoenix are so much easier than in other frameworks.",
  author: "realtime_dev",
  link_id: post2.id
})

Repo.insert!(%Comment{
  content: "Elixir's pattern matching makes real-time code very readable and maintainable.",
  author: "pattern_matcher",
  link_id: post2.id
})

Repo.insert!(%Comment{
  content: "Functional programming is definitely the future. Side effects are the root of all evil!",
  author: "fp_advocate",
  link_id: post3.id
})

Repo.insert!(%Comment{
  content: "I love how Elixir handles distributed systems. OTP is amazing.",
  author: "distributed_fan",
  link_id: post4.id
})

Repo.insert!(%Comment{
  content: "The fault tolerance in Elixir is what sold me on it for my startup.",
  author: "fault_tolerant",
  link_id: post5.id
})

Repo.insert!(%Comment{
  content: "GenServer is such a powerful abstraction. These patterns are very helpful.",
  author: "genserver_user",
  link_id: post6.id
})

Repo.insert!(%Comment{
  content: "This tutorial helped me build my first LiveView app. Great step-by-step guide!",
  author: "tutorial_follower",
  link_id: post7.id
})

Repo.insert!(%Comment{
  content: "Performance optimization in Elixir is fascinating. The BEAM VM is incredible.",
  author: "performance_enthusiast",
  link_id: post8.id
})

IO.puts("Seeded database with posts and comments!")