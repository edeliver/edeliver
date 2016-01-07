defmodule Edeliver.Relup.Instructions do
  @moduledoc """
    This record represents relup instructions from the
    relup file (http://www.erlang.org/doc/man/relup.html)
    but in a more accessible way.
    The up and down instructions can be modified and will
    be written back to the relup file before generating
    the release tar.
  """
  defstruct up_instructions: [],
            down_instructions: [],
            up_version: "",
            down_version: "",
            changed_modules: ""
end