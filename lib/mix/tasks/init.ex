defmodule Mix.Tasks.EspecPhoenix.Init do
  use Mix.Task
  import Mix.Generator

  @shortdoc "Create espec_phoenix folders and files"

  @moduledoc """
  Creates espec_phoenix folders and files.

  This task creates the following files:

    * `spec/phoenix_helper.exs`
    * `spec/espec_phoenix_extend.ex`
    * `spec/controllers/example_controller_spec.exs`
    * `spec/models/example_model_spec.exs`
    * `spec/requests/example_requests_spec.exs`
    * `spec/views/example/views_spec.exs`

  ## Command line options

  * `--skip-examples` - skip creating of example files

  """

  @spec_folder "spec"
  @phoenix_helper "phoenix_helper.exs"
  @espec_phoenix_extend "espec_phoenix_extend.ex"

  @controllers_folder "controllers"
  @controller_spec "example_controller_spec.exs"

  @models_folder "models"
  @model_spec "example_model_spec.exs"

  @requests_folder "requests"
  @request_spec "example_requests_spec.exs"

  @views_folder "views"
  @view_spec "example_views_spec.exs"

  def run(args) do
    {opts, _, _} = OptionParser.parse(args)
    app = Mix.Phoenix.base

    create_directories
    create_files(app)
    unless opts[:skip_examples] do
      create_examples(app)
    end
  end

  defp create_directories do
    create_directory Path.join(@spec_folder, @controllers_folder)
    create_directory Path.join(@spec_folder, @models_folder)
    create_directory Path.join(@spec_folder, @requests_folder)
    create_directory Path.join(@spec_folder, @views_folder)
  end

  defp create_files(app) do
    create_file(Path.join(@spec_folder, @phoenix_helper), phoenix_helper_template(nil))
    create_file(Path.join(@spec_folder, @espec_phoenix_extend), espec_phoenix_extend_template(app: app))
  end

  defp create_examples(app) do
    create_file(Path.join("#{@spec_folder}/#{@controllers_folder}", @controller_spec), controller_spec_template(app: app))
    create_file(Path.join("#{@spec_folder}/#{@models_folder}", @model_spec), model_spec_template(app: app))
    create_file(Path.join("#{@spec_folder}/#{@requests_folder}", @request_spec), request_spec_template(app: app))
    create_file(Path.join("#{@spec_folder}/#{@views_folder}", @view_spec), view_spec_template(app: app))
  end

  embed_template :phoenix_helper, """
  Code.require_file("spec/espec_phoenix_extend.ex")

  Mix.Task.run "ecto.create", ["--quiet"]
  Mix.Task.run "ecto.migrate", ["--quiet"]
  Ecto.Adapters.SQL.Sandbox.mode(App.Repo, :manual)
  """

  embed_template :espec_phoenix_extend, """
  defmodule ESpec.Phoenix.Extend do
    def model do
      quote do
        alias <%= @app %>.Repo
      end
    end

    def controller do
      quote do
        alias <%= @app %>.Repo
        import <%= @app %>.Router.Helpers
      end
    end

    def request do
      quote do
        alias <%= @app %>.Repo
        import <%= @app %>.Router.Helpers
      end
    end

    def view do
      quote do
        import <%= @app %>.Router.Helpers
      end
    end

    defmacro __using__(which) when is_atom(which) do
      apply(__MODULE__, which, [])
    end
  end
  """

  embed_template :controller_spec, """
  defmodule <%= @app %>.ExampleControllerSpec do
    use ESpec.Phoenix, controller: <%= @app %>.ExampleController

    describe "index" do
      let :examples do
        [
          %<%= @app %>.Example{title: "Example 1"},
          %<%= @app %>.Example{title: "Example 2"},
        ]
      end

      before do
        allow(<%= @app %>.Repo).to accept(:all, fn -> examples end)
      end

      subject do: action :index

      it do: should be_successful
      it do: should have_in_assigns(examples: examples)
    end
  end
  """

  embed_template :model_spec, """
  defmodule <%= @app %>.ExampleModelSpec do
    use ESpec.Phoenix, model: <%= @app %>.Example

    let :example, do: %<%= @app %>.Example{title: "Example 1"}
    it do: example.title |> should(eq "Example 1")
  end
  """

  embed_template :request_spec, """
  defmodule <%= @app %>.PostsRequestsSpec do
    use ESpec.Phoenix, request: <%= @app %>.Endpoint

    describe "index" do
      before do
        ex1 = %<%= @app %>.Example{title: "Example 1"} |> <%= @app %>.Repo.insert
        ex2 = %<%= @app %>.Example{title: "Example 2"} |> <%= @app %>.Repo.insert
        {:ok, ex1: ex1, ex2: ex2}
      end

      subject! do: get(conn(), examples_path(conn(), :index))

      it do: should be_successful
      it do: should be_success

      context "check body" do
        let :html, do: subject.resp_body

        it do: html |> should(have_content shared.ex1.title)
        it do: html |> should(have_text shared.ex2.title)
      end
    end
  end
  """

  embed_template :view_spec, """
  defmodule <%= @app %>.ExampleViewsSpec do
    use ESpec.Phoenix, view: <%= @app %>.ExamplesView

    describe "index html" do
      let :examples do
        [
          %<%= @app %>.Example{title: "Example 1"},
          %<%= @app %>.Example{title: "Example 2"},
        ]
      end

      subject do: render("index.html", examples: examples)

      it do: should have_content "Example 1"
      it do: should have_text "Example 2"
    end
  end
  """
end
