defmodule ReleaseManager.Plugin.ModifyRelup do
  use ReleaseManager.Plugin
  alias ReleaseManager.Utils
  alias Edeliver.Relup.Instructions

  def before_release(_), do: nil

  def after_release(config = %Config{env: :prod, upgrade?: true, version: version, name: name}) do
    case System.get_env "SKIP_RELUP_MODIFICATIONS" do
      "true" -> nil
      _ ->
        info "Modifying relup file..."
        relup_file = Utils.rel_dest_path(Path.join([name, "releases", version, "relup"]))
        exrm_relup_file = Utils.rel_dest_path(Path.join([name, "relup"]))
        relup_modification_module = case get_relup_modification_module do
          [] -> Edeliver.Relup.DefaultModification
          [module] -> module
          modules = [_|_] ->
            Mix.raise "Found multiple modules implementing behaviour Edeliver.Relup.DefaultModification:\n#{inspect modules}\nPlease use the --relup-mod=<module-name> option."
        end
        debug "Using #{inspect relup_modification_module} module for relup modification."
        if File.exists?(relup_file) do
          case :file.consult(relup_file) do
            {:ok, [{up_version,
                    [{down_version, up_description, up_instructions}],
                    [{down_version, down_description, down_instructions}]
                  }]} when is_atom(relup_modification_module) ->
              instructions = %Instructions{
                up_instructions: up_instructions,
                down_instructions: down_instructions,
                up_version: List.to_string(up_version),
                down_version: List.to_string(down_version),
                changed_modules: changed_modules(up_instructions, String.to_atom(name), String.to_char_list(version))
              }
              %Instructions{
                up_instructions: up_instructions,
                down_instructions: down_instructions,
              } = relup_modification_module.modify_relup(instructions, config)
              relup = [{up_version,
                [{down_version, up_description, up_instructions}],
                [{down_version, down_description, down_instructions}]
              }]
              write_relup(relup, relup_file)
              if File.exists?(exrm_relup_file), do: write_relup(relup, exrm_relup_file)
            error ->
              debug "Error when loading relup file: #{:io_lib.format('~p~n', [error])}"
              Mix.raise "Failed to load relup file from #{relup_file}\nYou can skip this step using the --skip-relup-mod option."
          end
        end
    end
  end
  def after_release(_), do: nil

  def after_cleanup(_), do: nil

  def after_package(_), do: nil

  defp changed_modules([{:load_object_code, {name, version, modules}}|_], name, version), do: modules
  defp changed_modules([_|rest], name, version), do: changed_modules(rest, name, version)
  defp changed_modules(_up_instructions, _name, _version), do: []

  defp write_relup(relup, relup_file) do
    case :file.open(relup_file, [:write]) do
      {:ok, fd} ->
        :io.format(fd, "~p.~n", [relup])
        :file.close(fd)
      {:error, reason} ->
         Mix.raise "Failed to save relup file to #{relup_file}. Reason: #{inspect reason}"
    end
  end

  defp get_relup_modification_module() do
    case System.get_env "RELUP_MODIFICATION_MODULE" do
      module = <<_,_::binary>> ->
        module = String.to_atom(module)
        if Code.ensure_loaded?(module) do
          [module]
        else
            Mix.raise "Module used by the --relup-mod=#{inspect module} option cannot be found."
        end
      _ -> # find module in path
        Path.wildcard("**/*/ebin/**/*.{beam}")
        |> Stream.map(fn path ->
          {:ok, {mod, chunks}} = :beam_lib.chunks('#{path}', [:attributes])
          {mod, get_in(chunks, [:attributes, :behaviour])}
        end)
        |> Stream.filter(fn {module, behaviours} ->
          is_list(behaviours) &&
          Edeliver.Relup.Modification in behaviours &&
          module != Edeliver.Relup.DefaultModification &&
          Code.ensure_loaded?(module)
        end)
        |> Enum.uniq
        |> Enum.map(fn {module, _} -> module end)
    end
  end

end
