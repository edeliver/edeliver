

defmodule Edeliver.BashScript.Case do
  use ExUnit.CaseTemplate

  using(args) do
    quote do
      @bash_script_file Keyword.get(unquote(args), :bash_script)

      @doc "Calls a function in the bash script"
      @spec call(bash_script_file::Path.t, function::String.t, args::[String.t]) :: String.t
      def call(bash_script_file = <<_,_::binary>>, function = <<_,_::binary>>, args) when is_list(args) do
        assert File.exists? bash_script_file
        args = args |> Enum.map(&("\\\"#{&1}\\\"")) |> Enum.join(" ")
        "/usr/bin/env bash -c \"
          set -e
          source \\\"#{bash_script_file}\\\"
          2>&1 #{function} #{args}
        \"" |> String.to_charlist() |> :os.cmd() |> IO.chardata_to_string() |> String.trim_trailing()
      end
      def call(function = <<_,_::binary>>, arg1 = <<_,_::binary>>, arg2 = <<_,_::binary>>), do: call(function, [arg1, arg2])
      def call(function = <<_,_::binary>>, arg1 = <<_,_::binary>>), do: call(function, [arg1])
      def call(function = <<_,_::binary>>, args) when is_list(args), do: call(@bash_script_file, function, args)
      def call(function = <<_,_::binary>>, arg1 = <<_,_::binary>>, arg2 = <<_,_::binary>>, arg3 = <<_,_::binary>>), do: call(function, [arg1, arg2, arg3])
      def call(function = <<_,_::binary>>), do: call(function, [])
      def call(function = <<_,_::binary>>, arg1, arg2, arg3, arg4), do: call(function, [arg1, arg2, arg3, arg4])
      def call(function = <<_,_::binary>>, arg1, arg2, arg3, arg4, arg5), do: call(function, [arg1, arg2, arg3, arg4, arg5])
      def call(function = <<_,_::binary>>, arg1, arg2, arg3, arg4, arg5, arg6), do: call(function, [arg1, arg2, arg3, arg4, arg5, arg6])

      @doc "Executes `expression` while setting the given environment variables"
      defmacro with_env(env_assignments, expression) do
        quote do
          old_env = System.get_env
          for {env, value} <- unquote(env_assignments) do
            env |> Atom.to_string() |> System.put_env(value)
          end
          try do
            unquote(expression)
          after
            for {env, value} <- unquote(env_assignments) do
              env = Atom.to_string(env)
              case Map.get(old_env, env) do
                nil -> System.delete_env(env)
                value -> System.put_env(env, value)
              end
            end
          end
        end
      end

    end # quote
  end # using
end #defmodule


ExUnit.start()
