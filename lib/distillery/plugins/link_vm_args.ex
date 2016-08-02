defmodule Releases.Plugin.LinkVMARgs do
  @moduledoc """
    Exrm plugin to link the `vm.args` file on deploy hosts.
  """
  use Mix.Releases.Plugin


  def before_assembly(_), do: nil

  def after_assembly(%Release{version: version, output_dir: output_dir}) do
    case System.get_env "LINK_VM_ARGS" do
      vm_args_link_destination = <<_,_::binary>> ->
        info "Linking vm.args file"
        vmargs_path = Path.join([output_dir, "releases", version, "vm.args"])
        if vmargs_path |> File.exists?, do: vmargs_path |> File.rm
        File.ln_s(vm_args_link_destination, vmargs_path)
        nil
      _ -> nil
    end
  end
  def after_assembly(_), do: nil

  def before_package(_), do: nil

  def after_package(_), do: nil

  def after_cleanup(_), do: nil

end
