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


  @typedoc "An [appup instruction](http://erlang.org/doc/man/appup.html) from the `relup` file"
  @type instruction :: :relup.instruction()
  @typedoc "A list of [appup instructions](http://erlang.org/doc/man/appup.html) from the `relup` file"
  @type instructions :: [instruction]

  @typedoc """
    [Appup instructions](http://erlang.org/doc/man/appup.html) from the `relup` file which can
    be modified. They are seperated into instructions for the upgrade and instructions for the
    downgrade and will be later written back to the relup file. `changed_modules` contains a
    list of all code modules which changed in the new version and will be loaded during the
    upgrade.
  """
  @type t :: %Edeliver.Relup.Instructions{
    up_instructions: instructions,
    down_instructions: instructions,
    up_version: String.t,
    down_version: String.t,
    changed_modules: [module]
  }
end