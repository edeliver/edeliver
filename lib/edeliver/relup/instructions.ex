defmodule Edeliver.Relup.Instructions do
  @moduledoc """
    This struct represents relup instructions from the [relup](http://www.erlang.org/doc/man/relup.html) file

    but in a more accessible way. The up and down instructions can be modified
    by a `Edeliver.Relup.Modification` and will be written back to the relup file
    by edeliver before generating the release tar.
  """
  defstruct up_instructions: [],
            down_instructions: [],
            up_version: "",
            down_version: "",
            changed_modules: []
end