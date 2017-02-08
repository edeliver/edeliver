defmodule Releases.Plugin.ModifyRelup do
  @moduledoc """
    Exrm plugin to auto-patch the relup file when building upgrades.
  """
  use Mix.Releases.Plugin
  alias Edeliver.Relup.Instructions

  def before_assembly(_), do: nil

  def after_assembly(release = %Release{is_upgrade: true, version: version, name: name, output_dir: output_dir}) do
    case System.get_env "SKIP_RELUP_MODIFICATIONS" do
      "true" -> nil
      _ ->
        info "Modifying relup file..."
        relup_file = Path.join([output_dir, "releases", version, "relup"])
        relup_modification_module = case get_relup_modification_module(release) do
          [module] -> module
          modules = [_|_] ->
            Mix.raise "Found multiple modules implementing behaviour Edeliver.Relup.DefaultModification:\n#{inspect modules}\nPlease use the --relup-mod=<module-name> option."
        end
        debug "Using #{inspect relup_modification_module} module for relup modification."
        if File.exists?(relup_file) do
          case :file.consult(to_char_list(relup_file)) do
            {:ok, [{up_version,
                    [{down_version, up_description, up_instructions}],
                    [{down_version, down_description, down_instructions}]
                  }]} when is_atom(relup_modification_module) ->
              instructions = %Instructions{
                up_instructions: up_instructions,
                down_instructions: down_instructions,
                up_version: List.to_string(up_version),
                down_version: List.to_string(down_version),
                changed_modules: changed_modules(up_instructions, name, String.to_char_list(version))
              }
              %Instructions{
                up_instructions: up_instructions,
                down_instructions: down_instructions,
              } = relup_modification_module.modify_relup(instructions, release)
              relup = {up_version,
                [{down_version, up_description, up_instructions}],
                [{down_version, down_description, down_instructions}]
              }
              write_relup(relup, relup_file)
            error ->
              debug "Error when loading relup file: #{:io_lib.format('~p~n', [error])}"
              Mix.raise "Failed to load relup file from #{relup_file}\nYou can skip this step using the --skip-relup-mod option."
          end
        end
    end
    nil
  end
  def after_assembly(_), do: nil

  def before_package(_), do: nil

  def after_package(_), do: nil

  def after_cleanup(_), do: nil

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

  defp get_relup_modification_module(release = %Release{}) do
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
        |> Stream.filter_map(fn {module, behaviours} ->
          is_list(behaviours) &&
          Edeliver.Relup.Modification in behaviours &&
          Code.ensure_loaded?(module) &&
          module.usable?(release)
        end, fn {module, _} ->
          {module, module.priority}
        end)
        |> Enum.uniq()
        |> Enum.sort(fn {module_a, priority_a}, {module_b, priority_b} ->
          cond do
            module_a == module_b -> true
            String.starts_with?(Atom.to_string(module_a), "Elixir.Edeliver.Relup.") -> false # prefer custom modules
            priority_a < priority_b -> false
            true -> true
          end
        end)
        |> Enum.reduce({[], nil}, fn {module, priority}, {modules, highest_priority} ->
          highest_priority = if highest_priority == nil, do: priority, else: highest_priority
          modules = if priority == highest_priority, do: [module|modules], else: modules
          {modules, highest_priority}
        end)
        |> Tuple.to_list
        |> List.first
        |> Enum.reverse
    end
  end

end
