defmodule Mix.Tasks.Redeagle.New do
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
    Mix.shell().info("Redeagle installer v#{@version}")
  end

  def run(argv) do
    argv =
      List.insert_at(
        ["--no-assets", "--no-html", "--no-gettext", "--no-dashboard"],
        0,
        argv |> Enum.at(0)
      )

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
    |> prompt_to_install_docker(generator, path)
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

  defp prompt_to_install_deps(%Project{} = project, generator, path_key) do
    path = Map.fetch!(project, path_key)

    install? =
      Keyword.get_lazy(project.opts, :install, fn ->
        Mix.shell().yes?("\nFetch and install dependencies?")
      end)

    cd_step = ["$ cd #{relative_app_path(path)}"]

    maybe_cd(path, fn ->
      mix_step = install_mix(project, install?)

      if mix_step == [] and rebar_available?() do
        cmd(project, "mix deps.compile")
      end

      print_missing_steps(cd_step ++ mix_step)

      if path_key == :web_path do
        Mix.shell().info("""
        Your web app requires a PubSub server to be running.
        The PubSub server is typically defined in a `mix phx.new.ecto` app.
        If you don't plan to define an Ecto app, you must explicitly start
        the PubSub in your supervision tree as:

            {Phoenix.PubSub, name: #{inspect(project.app_mod)}.PubSub}
        """)
      end

      print_mix_info(generator)
    end)
  end

  defp prompt_to_install_docker(%Project{} = project, generator, path_key) do
    path = Map.fetch!(project, path_key)

    install? =
      Keyword.get_lazy(project.opts, :install, fn ->
        Mix.shell().yes?(
          "\nRun Docker commands? (You need to have docker running on your machine!)"
        )
      end)

    if install? do
      with {:ok} <- cmd("docker-compose build", relative_app_path(path)),
           {:ok} <- cmd("docker-compose run --rm api mix setup", relative_app_path(path)),
           {:ok} <- cmd("docker-compose run --rm react npm i --silent", relative_app_path(path)),
           {:ok} <- cmd("docker-compose up -d api", relative_app_path(path)),
           {:ok} <- cmd("docker-compose up -d react", relative_app_path(path)) do
        print_mix_info(generator, true)
      else
        _ ->
          print_mix_info(generator)
      end
    else
      print_mix_info(generator)
    end
  end

  defp maybe_cd(path, func), do: path && File.cd!(path, func)

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

  defp install_mix(project, install?) do
    maybe_cmd(project, "mix deps.get", true, install? && hex_available?())
  end

  defp hex_available? do
    Code.ensure_loaded?(Hex)
  end

  defp rebar_available? do
    Mix.Rebar.rebar_cmd(:rebar3)
  end

  defp print_missing_steps(steps) do
    Mix.shell().info("""

    We are almost there! The following steps are missing:

        #{Enum.join(steps, "\n    ")}
    """)
  end

  defp print_ecto_info(Web), do: :ok

  defp print_ecto_info(_gen) do
    Mix.shell().info("""
    Then configure your database in config/dev.exs and run:

        $ mix ecto.create
    """)
  end

  defp print_mix_info(Ecto) do
    Mix.shell().info("""
    You can run your app inside IEx (Interactive Elixir) as:

        $ iex -S mix
    """)
  end

  defp print_mix_info(_gen) do
    Mix.shell().info("""
    Start your Redeagle app with:

        $ docker-compose build
        $ docker-compose run --rm api mix setup
        $ docker-compose run --rm react npm i --silent
        $ docker-compose up -d api
        $ docker-compose up -d react

        Now you can visit front-end [`localhost:3000`](http://localhost:3000) from your browser.
        Your back-end is in [`localhost:4000/dashboard`](http://localhost:4000)
    """)
  end

  defp print_mix_info(_gen, install?) do
    Mix.shell().info("""
    Start your Redeagle app with:

        Now you can visit front-end [`localhost:3000`](http://localhost:3000) from your browser.
        Your back-end is in [`localhost:4000/dashboard`](http://localhost:4000)
    """)
  end

  defp relative_app_path(path) do
    case Path.relative_to_cwd(path) do
      ^path -> Path.basename(path)
      rel -> rel
    end
  end

  ## Helpers

  defp maybe_cmd(project, cmd, should_run?, can_run?) do
    cond do
      should_run? && can_run? ->
        cmd(project, cmd)

      should_run? ->
        ["$ #{cmd}"]

      true ->
        []
    end
  end

  defp cmd(cmd, path) do
    Mix.shell().info([:green, "* running ", :reset, cmd])

    case Mix.shell().cmd(cmd, cd: path, quiet: true) do
      0 ->
        Mix.shell().info([:green, "* done ", :reset, cmd])
        {:ok}

      _ ->
        Mix.shell().info([:red, "* error ", :reset, cmd])
        {:error}
    end
  end

  defp cmd(%Project{} = project, cmd) do
    Mix.shell().info([:green, "* running ", :reset, cmd])

    case Mix.shell().cmd(cmd, cmd_opts(project)) do
      0 ->
        []

      _ ->
        ["$ #{cmd}"]
    end
  end

  defp cmd_opts(%Project{} = project) do
    if Project.verbose?(project) do
      []
    else
      [quiet: true]
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
