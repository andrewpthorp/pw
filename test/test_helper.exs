defmodule MockIO do
  def puts(_str), do: ""
  def stream(:stdio, :line), do: ["username: foo\n", "password: bar\n", ""]
end

ExUnit.start()
