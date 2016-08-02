defmodule Releases.Plugin.LinkConfig do
  @moduledoc """
    Exrm plugin to link the `vm.args` or `sys.config` file on deploy hosts.

    Because distillery uses `:systools_make.make_tar(...)` to create the release
    tar which resoves all links using the `:dereference` option, the release
    tar needs to be repackaged including the links. To be able use this plugin,
    it must be added in the `rel/config.exs` distillery config as plugin like this:

    ```
    environment :prod do
      ..
      plugin Releases.Plugin.LinkConfig
    end
    ```
  """
  use Mix.Releases.Plugin


  def before_assembly(_), do: nil

  def after_assembly(%Release{version: version, output_dir: output_dir}) do
    # link files in release dir
    case System.get_env "LINK_VM_ARGS" do
      vm_args_link_destination = <<_,_::binary>> ->
        info "Linking vm.args file"
        vmargs_path = Path.join([output_dir, "releases", version, "vm.args"])
        if vmargs_path |> File.exists?, do: vmargs_path |> File.rm
        File.ln_s(vm_args_link_destination, vmargs_path)
      _ -> nil
    end
    case System.get_env "LINK_SYS_CONFIG" do
      sys_config_link_destination = <<_,_::binary>> ->
        info "Linking sys.config file"
        sysconfig_path = Path.join([output_dir, "releases", version, "sys.config"])
        if sysconfig_path |> File.exists?, do: sysconfig_path |> File.rm
        File.ln_s(sys_config_link_destination, sysconfig_path)
      _ -> nil
    end
    nil
  end
  def after_assembly(_), do: nil

  def before_package(_), do: nil

  def after_package(%Release{version: version, output_dir: output_dir, name: name}) do
    # repackage release tar including link, because tar is generated using `:systools_make.make_tar(...)`
    # which resoves the links using the `:dereference` option when creating the tar using the
    # `:erl_tar` module.
    tmp_dir = "_edeliver_release_patch"
    tmp_path = Path.join [output_dir, "releases", version, tmp_dir]
    files_to_link = [
      {System.get_env("LINK_VM_ARGS"),    Path.join([tmp_path, "releases", version, "vm.args"])},
      {System.get_env("LINK_SYS_CONFIG"), Path.join([tmp_path, "releases", version, "sys.config"])},
    ] |> Enum.filter(fn {source, _dest} ->
      case source do
        <<_,_::binary>> -> true
        _ -> false
      end
    end)
    if Enum.count(files_to_link) > 0 do
      info "Repackaging release with config links"
      try do
        tar_file = Path.join [output_dir, "releases", version, "#{name}.tar.gz"]
        true = File.exists? tar_file
        :ok = File.mkdir_p tmp_path
        tar_binary = <<_,_::binary>> = System.find_executable "tar"
        ln_binary = <<_,_::binary>>  = System.find_executable "ln"
        debug "Extracting release tar to #{tmp_dir}"
        {_, 0} = System.cmd tar_binary, ["-xzvf", tar_file, "-C", tmp_path], stderr_to_stdout: true
        for {source, destination} <- files_to_link do
          debug "Linking #{source} to #{destination}"
          {_, 0} = System.cmd ln_binary,  ["-sf", source, destination], stderr_to_stdout: true
        end
        debug "Recreating release tar including links"
        {_, 0} = System.cmd tar_binary, ["-czvf", tar_file, "-C", tmp_path, "."], stderr_to_stdout: true
      after
        tmp_path_exists? = File.exists?(tmp_path) && File.dir?(tmp_path)
        tmp_path_empty? = tmp_path_exists? && File.ls!(tmp_path) == []
        tmp_path_contains_rel? = File.exists?(Path.join(tmp_path, "lib")) || File.exists?(Path.join(tmp_path, "releases"))
        if tmp_path_exists? && (tmp_path_empty? || tmp_path_contains_rel?) do
          debug "Removing tmp dir used for repackaging tar: #{tmp_path}"
          File.rm_rf!(tmp_path)
        end
      end
    end
    nil
  end

  def after_cleanup(_), do: nil

end
