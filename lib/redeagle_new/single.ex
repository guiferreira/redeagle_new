defmodule Redeagle.New.Single do
  @moduledoc false
  use Redeagle.New.Generator
  alias Redeagle.New.{Project}

  template(:new, [
    {:eex, "phx_single/config/dev.exs", :project, "config/dev.exs"},
    {:eex, "phx_single/config/test.exs", :project, "config/test.exs"},
    {:eex, "phx_single/config/prod.exs", :project, "config/prod.exs"},
    {:eex, "redeagle_docker/docker-compose.yml", :project, "docker-compose.yml"},
    {:eex, "redeagle_docker/Dockerfile-elixir", :project, "Dockerfile-elixir"},
    {:eex, "redeagle_docker/Dockerfile-react", :project, "Dockerfile-react"},
    {:keep, "redeagle_react", :project, "react"},
    {:keep, "redeagle_react/public", :project, "react/public"},
    {:keep, "redeagle_react/src", :project, "react/src"},
    {:text, "redeagle_react/public/favicon.ico", :project, "react/public/favicon.ico"},
    {:text, "redeagle_react/public/index.html", :project, "react/public/index.html"},
    {:text, "redeagle_react/public/logo192.png", :project, "react/public/logo192.png"},
    {:text, "redeagle_react/public/logo512.png", :project, "react/public/logo512.png"},
    {:text, "redeagle_react/public/manifest.json", :project, "react/public/manifest.json"},
    {:text, "redeagle_react/public/robots.txt", :project, "react/public/robots.txt"},
    {:keep, "redeagle_react/src/pages", :project, "react/src/pages"},
    {:keep, "redeagle_react/src/pages/Home", :project, "react/src/pages/Home"},
    {:text, "redeagle_react/src/pages/Home/index.jsx", :project, "react/src/pages/Home/index.jsx"},
    {:keep, "redeagle_react/src/routes", :project, "react/src/routes"},
    {:text, "redeagle_react/src/routes/index.jsx", :project, "react/src/routes/index.jsx"},
    {:keep, "redeagle_react/src/styles", :project, "react/src/styles"},
    {:text, "redeagle_react/src/styles/global-styles.css", :project, "react/src/styles/global-styles.css"},
    {:text, "redeagle_react/src/index.js", :project, "react/src/index.js"},
    {:text, "redeagle_react/src/phoenix.png", :project, "react/src/phoenix.png"},
    {:text, "redeagle_react/src/logo.svg", :project, "react/src/logo.svg"},
    {:text, "redeagle_react/src/docker.webp", :project, "react/src/docker.webp"},
    {:text, "redeagle_react/src/reportWebVitals.js", :project, "react/src/reportWebVitals.js"},
    {:text, "redeagle_react/src/setupTests.js", :project, "react/src/setupTests.js"},
    {:text, "redeagle_react/.gitignore", :project, "react/.gitignore"},
    {:text, "redeagle_react/package.json", :project, "react/package.json"}
  ])

  template(:gettext, [])

  template(:html, [])

  template(:ecto, [])

  template(:assets, [])

  template(:no_assets, [])

  template(:static, [])

  template(:mailer, [])

  def prepare_project(%Project{app: app} = project) when not is_nil(app) do
    %Project{project | project_path: project.base_path}
    |> put_app()
    |> put_root_app()
    |> put_web_app()
  end

  defp put_app(%Project{base_path: base_path} = project) do
    %Project{project | in_umbrella?: in_umbrella?(base_path), app_path: base_path}
  end

  defp put_root_app(%Project{app: app, opts: opts} = project) do
    %Project{
      project
      | root_app: app,
        root_mod: Module.concat([opts[:module] || Macro.camelize(app)])
    }
  end

  defp put_web_app(%Project{app: app} = project) do
    %Project{
      project
      | web_app: app,
        lib_web_name: "#{app}_web",
        web_namespace: Module.concat(["#{project.root_mod}Web"]),
        web_path: project.project_path
    }
  end

  def generate(%Project{} = project) do
    copy_from(project, __MODULE__, :new)

    if Project.ecto?(project), do: gen_ecto(project)
    if Project.html?(project), do: gen_html(project)
    if Project.mailer?(project), do: gen_mailer(project)
    if Project.gettext?(project), do: gen_gettext(project)

    gen_assets(project)
    project
  end

  def gen_html(project) do
    copy_from(project, __MODULE__, :html)
  end

  def gen_gettext(project) do
    copy_from(project, __MODULE__, :gettext)
  end

  def gen_ecto(project) do
    copy_from(project, __MODULE__, :ecto)
    gen_ecto_config(project)
  end

  def gen_assets(%Project{} = project) do
    if Project.assets?(project) or Project.html?(project) do
      command = if Project.assets?(project), do: :assets, else: :no_assets
      copy_from(project, __MODULE__, command)
      copy_from(project, __MODULE__, :static)
    end
  end

  def gen_mailer(%Project{} = project) do
    copy_from(project, __MODULE__, :mailer)
  end
end
