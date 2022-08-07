Code.require_file "mix_helper.exs", __DIR__

defmodule RedeagleTest do
  use ExUnit.Case, async: false
  import MixHelper
  import ExUnit.CaptureIO

  @app_name "new_app"

  setup do
    # The shell asks to install deps.
    # We will politely say not.
    send self(), {:mix_shell_input, :yes?, false}
    :ok
  end

  test "returns the version" do
    Mix.Tasks.Redeagle.New.run(["-v"])
    assert_received {:mix_shell, :info, ["Redeagle installer v" <> _]}
  end

  test "redeagle.new " do
    in_tmp "with defaults", fn ->
      Mix.Tasks.Redeagle.New.run([@app_name])

      # App Elixir
      assert_file "new_app/README.md"

      assert_file "new_app/mix.exs", fn file ->
        assert file =~ "app: :new_app"
        refute file =~ "deps_path: \"../../deps\""
        refute file =~ "lockfile: \"../../mix.lock\""
      end

      assert_file "new_app/config/config.exs", fn file ->
        assert file =~ "ecto_repos: [NewApp.Repo]"
        assert file =~ "config :phoenix, :json_library, Jason"
        refute file =~ "namespace: NewApp"
        refute file =~ "config :new_app, :generators"
      end

      assert_file "new_app/config/prod.exs", fn file ->
        assert file =~ "port: 443"
      end

      assert_file "new_app/config/runtime.exs", ~r/ip: {0, 0, 0, 0, 0, 0, 0, 0}/

      assert_file "new_app/lib/new_app/application.ex", ~r/defmodule NewApp.Application do/
      assert_file "new_app/lib/new_app.ex", ~r/defmodule NewApp do/
      assert_file "new_app/mix.exs", fn file ->
        assert file =~ "mod: {NewApp.Application, []}"
        assert file =~ "{:jason,"
      end

      # Ecto
      config = ~r/config :new_app, NewApp.Repo,/
      assert_file "new_app/mix.exs", fn file ->
        assert file =~ "{:phoenix_ecto,"
        assert file =~ "aliases: aliases()"
        assert file =~ "ecto.setup"
        assert file =~ "ecto.reset"
      end
      assert_file "new_app/config/dev.exs", config
      assert_file "new_app/config/test.exs", config
      assert_file "new_app/config/runtime.exs", fn file ->
        assert file =~ config
        assert file =~ ~S|maybe_ipv6 = if System.get_env("ECTO_IPV6"), do: [:inet6], else: []|
        assert file =~ ~S|socket_options: maybe_ipv6|
        assert file =~ """
        if System.get_env("PHX_SERVER") do
          config :new_app, NewAppWeb.Endpoint, server: true
        end
        """
        assert file =~ ~S[host = System.get_env("PHX_HOST") || "example.com"]
        assert file =~ ~S|url: [host: host, port: 443, scheme: "https"],|
      end

      # Mailer
      assert_file "new_app/mix.exs", fn file ->
        assert file =~ "{:swoosh, \"~> 1.3\"}"
      end

      assert_file "new_app/lib/new_app/mailer.ex", fn file ->
        assert file =~ "defmodule NewApp.Mailer do"
        assert file =~ "use Swoosh.Mailer, otp_app: :new_app"
      end

      assert_file "new_app/config/config.exs", fn file ->
        assert file =~ "config :new_app, NewApp.Mailer, adapter: Swoosh.Adapters.Local"
      end

      assert_file "new_app/config/test.exs", fn file ->
        assert file =~ "config :swoosh"
        assert file =~ "config :new_app, NewApp.Mailer, adapter: Swoosh.Adapters.Test"
      end

      assert_file "new_app/config/dev.exs", fn file ->
        assert file =~ "config :swoosh"
      end

      # Docker
      assert_file "new_app/docker-compose.yml", fn file ->
        assert file =~ "container_name: react"
        assert file =~ "dockerfile: Dockerfile-react"
        assert file =~ "- ./react:/app"
        assert file =~ "container_name: api"
        assert file =~ "dockerfile: Dockerfile-elixir"
        assert file =~ "- .:/elixir"
      end

      assert_file "new_app/Dockerfile-elixir", fn file ->
        assert file =~ "FROM bitwalker/alpine-elixir-phoenix:1.12"
      end

      assert_file "new_app/Dockerfile-react", fn file ->
        assert file =~ "FROM node:13-alpine"
      end

      # React
      assert_file "new_app/react/package.json", fn file ->
        assert file =~ "\"name\": \"web\""
      end
    end
  end
end

