defmodule CliTest do
  use ExUnit.Case

  import PW.CLI, only: [parse_args: 1]

  test ":help returned by option parsing with -h and --help options" do
    assert parse_args(["-h", "foo"]) == :help
    assert parse_args(["--help", "bar"]) == :help
  end

  test "return :help if invalid options passed" do
    assert parse_args([]) == :help
  end
end
