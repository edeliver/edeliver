defmodule ReleaseManager.Plugin.LinkVMARgs do
  @moduledoc """
    Exrm plugin to link the `vm.args` file on deploy hosts.
  """
  use ReleaseManager.Plugin
  alias  ReleaseManager.Utils


  def before_release(_), do: nil

  def after_release(%Config{version: version, name: name}) do
    case System.get_env "LINK_VM_ARGS" do
      vm_args_link_destination = <<_,_::binary>> ->
        debug "Linking vm.args file"
        vmargs_path = Utils.rel_dest_path(Path.join([name, "releases", version, "vm.args"]))
        if vmargs_path |> File.exists?, do: vmargs_path |> File.rm
        File.ln_s(vm_args_link_destination, vmargs_path)
      _ -> nil
    end
  end
  def after_release(_), do: nil

  def after_cleanup(_), do: nil

  def after_package(_), do: nil

end
