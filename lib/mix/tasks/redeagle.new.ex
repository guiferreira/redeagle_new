defmodule Mix.Tasks.Redeagle.New do
  @moduledoc """
  ## RedEagle New

  This package will provide an installer for Phoenix and React projects using Docker.

  ## Installation

      $ mix archive.install hex redeagle_new

  ## Creating a project with Phoenix + React + Docker:

      $ mix redeagle.new my_app

  """

  use Mix.Task
  alias Redeagle.New.{Generator, Project, Single}
  @version Mix.Project.config()[:version]

  @switches [
    dev: :boolean,
    assets: :boolean,
    ecto: :boolean,
    app: :string,
    module: :string,
    web_module: :string,
    database: :string,
    binary_id: :boolean,
    html: :boolean,
    gettext: :boolean,
    umbrella: :boolean,
    verbose: :boolean,
    live: :boolean,
    dashboard: :boolean,
    install: :boolean,
    prefix: :string,
    mailer: :boolean
  ]

  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("RedEagle New v#{@version}")
  end

  def run(argv) do
    argv =
      case argv do
        [] ->
          []

        _ ->
          List.insert_at(
            ["--no-assets", "--no-html"],
            0,
            argv |> Enum.at(0)
          )
      end

    elixir_version_check!()

    case parse_opts(argv) do
      {_opts, []} ->
        Mix.Tasks.Help.run(["redeagle.new"])

      {opts, [base_path | _]} ->
        case Mix.Task.get("phx.new") do
          nil ->
            :error

          _ ->
            generate(base_path, Phx.New.Single, :project_path, opts)
            File.rm("#{base_path}/config/dev.exs")
            File.rm("#{base_path}/config/test.exs")
            File.rm("#{base_path}/config/prod.exs")
            generate_redeagle(base_path, Single, :project_path, opts)
        end

      _ ->
        Mix.shell().info("RedEagle New v#{@version}")

        Mix.shell().info(
          "This package will provide an installer for Phoenix and React projects using Docker."
        )

        Mix.shell().info("Run: mix redeagle.new my_app")
    end
  end

  defp generate(base_path, generator, path, opts) do
    base_path
    |> Phx.New.Project.new(opts)
    |> generator.prepare_project()
    |> Phx.New.Generator.put_binding()
    |> validate_project(path)
    |> generator.generate()
  end

  defp generate_redeagle(base_path, generator, path, opts) do
    base_path
    |> Project.new(opts)
    |> generator.prepare_project()
    |> Generator.put_binding()
    |> generator.generate()
    |> prompt_to_install_docker(path, base_path)
  end

  defp validate_project(%Phx.New.Project{opts: opts} = project, path) do
    check_app_name!(project.app, !!opts[:app])
    check_directory_existence!(Map.fetch!(project, path))
    check_module_name_validity!(project.root_mod)
    check_module_name_availability!(project.root_mod)

    project
  end

  defp validate_project(%Project{opts: opts} = project, path) do
    check_app_name!(project.app, !!opts[:app])
    check_directory_existence!(Map.fetch!(project, path))
    check_module_name_validity!(project.root_mod)
    check_module_name_availability!(project.root_mod)

    project
  end

  defp prompt_to_install_docker(%Project{} = project, path_key, base_path) do
    path = Map.fetch!(project, path_key)

    Mix.shell().info([
      :yellow,
      "* Warning ",
      :reset,
      "You need to have docker running on your machine!"
    ])

    Mix.shell().info([:yellow, "* Warning ", :reset, "Stop all your Docker projects"])

    install? =
      Keyword.get_lazy(project.opts, :install, fn ->
        Mix.shell().yes?("\nRun Docker commands?")
      end)

    if install? do
      cmd("docker-compose build", relative_app_path(path))
      cmd("docker-compose run --rm api mix setup", relative_app_path(path))
      cmd("docker-compose run --rm react npm i --silent", relative_app_path(path))
      cmd("docker-compose up -d api", relative_app_path(path))
      cmd("docker-compose up -d react", relative_app_path(path))
    end

    print_mix_info(base_path)
  end

  defp cmd(cmd, path) do
    Mix.shell().info([:green, "* running ", :reset, cmd])

    case Mix.shell().cmd(cmd, cd: path) do
      0 ->
        Mix.shell().info([:green, "* done ", :reset, cmd])
        {:ok}

      _ ->
        Mix.shell().info([:red, "* error ", :reset, cmd])
        {:error}
    end
  end

  defp parse_opts(argv) do
    case OptionParser.parse(argv, strict: @switches) do
      {opts, argv, []} ->
        {opts, argv}

      {_opts, _argv, [switch | _]} ->
        Mix.raise("Invalid option: " <> switch_to_string(switch))
    end
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp print_mix_info(base_path) do
    Mix.shell().info("""
    Start your Redeagle app with:

        $ cd #{base_path}
        $ docker-compose build
        $ docker-compose run --rm api mix setup
        $ docker-compose run --rm react npm i --silent
        $ docker-compose up -d api
        $ docker-compose up -d react

        Wait for docker to process and go to:
        Front-end http://localhost:3000 from your browser.
        Back-end http://localhost:4000/dashboard from your browser.
    """)
  end

  defp relative_app_path(path) do
    case Path.relative_to_cwd(path) do
      ^path -> Path.basename(path)
      rel -> rel
    end
  end

  defp check_app_name!(name, from_app_flag) do
    unless name =~ Regex.recompile!(~r/^[a-z][\w_]*$/) do
      extra =
        if !from_app_flag do
          ". The application name is inferred from the path, if you'd like to " <>
            "explicitly name the application then use the `--app APP` option."
        else
          ""
        end

      Mix.raise(
        "Application name must start with a letter and have only lowercase " <>
          "letters, numbers and underscore, got: #{inspect(name)}" <> extra
      )
    end
  end

  defp check_module_name_validity!(name) do
    unless inspect(name) =~ Regex.recompile!(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp check_module_name_availability!(name) do
    [name]
    |> Module.concat()
    |> Module.split()
    |> Enum.reduce([], fn name, acc ->
      mod = Module.concat([Elixir, name | acc])

      if Code.ensure_loaded?(mod) do
        Mix.raise("Module name #{inspect(mod)} is already taken, please choose another name")
      else
        [name | acc]
      end
    end)
  end

  defp check_directory_existence!(path) do
    if File.dir?(path) and
         not Mix.shell().yes?(
           "The directory #{path} already exists. Are you sure you want to continue?"
         ) do
      Mix.raise("Please select another directory for installation.")
    end
  end

  defp elixir_version_check! do
    unless Version.match?(System.version(), "~> 1.12") do
      Mix.raise(
        "Phoenix v#{@version} requires at least Elixir v1.12.\n " <>
          "You have #{System.version()}. Please update accordingly"
      )
    end
  end
end
