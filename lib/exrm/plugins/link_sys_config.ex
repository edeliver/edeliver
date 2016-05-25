defmodule ReleaseManager.Plugin.LinkSysConfig do
  @moduledoc """
    Exrm plugin to link the `sys.config` file on deploy hosts.
  """
  use ReleaseManager.Plugin
  alias  ReleaseManager.Utils


  def before_release(_), do: nil

  def after_release(%Config{version: version, name: name}) do
    case System.get_env "LINK_SYS_CONFIG" do
      sys_config_link_destination = <<_,_::binary>> ->
        debug "Linking sys.config file"
        sysconfig_path = Utils.rel_dest_path(Path.join([name, "releases", version, "sys.config"]))
        if sysconfig_path |> File.exists?, do: sysconfig_path |> File.rm
        File.ln_s(sys_config_link_destination, sysconfig_path)
      _ -> nil
    end
  end
  def after_release(_), do: nil

  def after_cleanup(_), do: nil

  def after_package(_), do: nil

end
