defmodule Edeliver do


  def run_command([command_name, application_name = [_|_] | arguments]) when is_atom(command_name) do
    application_name = to_string(application_name)
    application_name = String.to_atom(to_string(application_name))
    {^application_name, _description, application_version} = :application.which_applications |> List.keyfind application_name, 0
    application_version = to_string application_version
    apply __MODULE__, command_name, [application_name, application_version | arguments]
  end

  def release_version(application_name, _application_version \\ nil) do
    releases = :release_handler.which_releases
    application_name = Atom.to_char_list application_name
    case (for {name, version, _apps, status} <- releases, status == :current and name == application_name, do: to_string(version)) do
      [current_version] -> current_version
      _ ->
        case (for {name, version, _apps, status} <- releases, status == :permanent and name == application_name, do: to_string(version)) do
          [permanent_version] -> String.to_char_list(permanent_version)
        end
    end
  end

  def list_pending_migrations(application_name, application_version) do
    repository = ecto_repository!
    versions = Ecto.Migrator.migrated_versions(repository)
    pending_migrations = migrations_for(migrations_dir(application_name, application_version))
    |> Enum.filter(fn {version, _name, _file} -> not (version in versions) end)
    |> Enum.reverse
    |> Enum.map(fn {version, name, _file} -> {version, name} end)
    pending_migrations |> Enum.each(fn {version, name} ->
      warning "pending: #{name} (#{version})"
    end)
    if length(pending_migrations) > 0, do: throw "error"
  end

  def migrate(application_name, application_version, direction, migration_version \\ :all) do
    direction = String.to_atom direction
    options = if migration_version == :all, do: [all: true], else: [to: to_string(migration_version)]
    Ecto.Migrator.run(ecto_repository!, migrations_dir(application_name, application_version), direction, options)
  end

  def migrations_dir(application_name, application_version) do
    # use priv dir from installed version
    lib_dir = :code.priv_dir(application_name) |> to_string |> Path.dirname |> Path.dirname
    application_with_version = "#{Atom.to_string(application_name)}-#{application_version}"
    Path.join([lib_dir, application_with_version, "priv", "repo", "migrations"])
  end

  def ecto_repository! do
    case System.get_env "ECTO_REPOSITORY" do
      ecto_repository = <<_,_::binary>> ->
        ecto_repository_module = List.to_atom ecto_repository
        unless :erlang.module_loaded(ecto_repository_module) && (ecto_repository_module.module_info(:exports) |> Dict.get(:__repo__, nil)) do
          error! "Module '#{ecto_repository_module}' is not an ecto repository.\n    Please set the correct repository module in the edeliver config as ECTO_REPOSITORY env\n    or remove that value to use autodetection of that module."
        else
          ecto_repository_module
        end
      _ ->
        case Enum.filter(:erlang.loaded |> Enum.reverse, fn(module) -> :erlang.module_loaded(module) && (module.module_info(:exports) |> Dict.get(:__repo__, nil)) end) do
          [ecto_repository_module] -> ecto_repository_module
          [] -> error! "No ecto repository module found.\n    Please specify the repository in the edeliver config as ECTO_REPOSITORY env."
          modules =[_|_] -> error! "Found several ecto repository modules (#{inspect modules}).\n    Please specify the repository to use in the edeliver config as ECTO_REPOSITORY env."
        end
    end
  end


  # taken from https://github.com/elixir-lang/ecto/blob/master/lib/ecto/migrator.ex#L183
  defp migrations_for(directory) do
    query = Path.join(directory, "*")
    for entry <- Path.wildcard(query),
      info = extract_migration_info(entry),
      do: info
  end

  defp extract_migration_info(file) do
    base = Path.basename(file)
    ext  = Path.extname(base)
    case Integer.parse(Path.rootname(base)) do
      {integer, "_" <> name} when ext == ".exs" -> {integer, name, file}
      _ -> nil
    end
  end

  # defp info(message),    do: IO.puts "==> #{IO.ANSI.green}#{message}#{IO.ANSI.reset}"
  defp warning(message), do: IO.puts "==> #{IO.ANSI.yellow}#{message}#{IO.ANSI.reset}"
  defp error!(message) do
     IO.puts "==> #{IO.ANSI.red}#{message}#{IO.ANSI.reset}"
     throw "error"
  end


end