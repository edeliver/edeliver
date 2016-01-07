defmodule ReleaseManager.Plugin.ModifyRelup do
  use ReleaseManager.Plugin
  alias ReleaseManager.Utils


  def before_release(_), do: nil

  def after_release(_config = %Config{env: :prod, upgrade?: true, version: version, name: name}) do
    case System.get_env "SKIP_RELUP_MODIFICATIONS" do
      "true" -> nil
      _ ->
        info "Modifying relup file"
        relup_file = Utils.rel_dest_path(Path.join([name, "releases", version, "relup"]))
        if File.exists?(relup_file) do
          case :file.consult(relup_file) do
            {:ok, relup_instructions} -> IO.inspect relup_instructions
            _ -> :error
          end
        end
    end
  end
  def after_release(_), do: nil

  def after_cleanup(_), do: nil

  def after_package(_), do: nil

end
