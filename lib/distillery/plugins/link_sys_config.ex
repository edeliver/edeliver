defmodule Releases.Plugin.LinkSysConfig do
  @moduledoc """
    Exrm plugin to link the `sys.config` file on deploy hosts.
  """
  use Mix.Releases.Plugin


  def before_assembly(_), do: nil

  def after_assembly(%Release{version: version, output_dir: output_dir}) do
    case System.get_env "LINK_SYS_CONFIG" do
      sys_config_link_destination = <<_,_::binary>> ->
        info "Linking sys.config file"
        sysconfig_path = Path.join([output_dir, "releases", version, "sys.config"])
        if sysconfig_path |> File.exists?, do: sysconfig_path |> File.rm
        File.ln_s(sys_config_link_destination, sysconfig_path)
        nil
      _ -> nil
    end
  end
  def after_assembly(_), do: nil

  def before_package(_), do: nil

  def after_package(_), do: nil

  def after_cleanup(_), do: nil

end
