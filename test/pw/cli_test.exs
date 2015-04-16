defmodule FakeIO do
  def puts(_str), do: ""
  def stream(:stdio, :line), do: ["username: foo\n", "password: bar\n", ""]
end

defmodule PW.CLITest do
  use ExUnit.Case, async: false
  import PW.CLI

  setup do
    Application.put_env(:pw, :directory, "test/data")
    Application.put_env(:pw, :io, FakeIO)
    Application.put_env(:pw, :recipient, "foo@bar.com")
  end

  test "argument parser" do
    assert parse_args(["-h", "foo"]) == :usage
    assert parse_args(["--help", "foo"]) == :usage
    assert parse_args([]) == :usage
    assert parse_args(["add", "google"]) == {["add", "google"], []}
    assert parse_args(["rm"]) == {["rm"], []}
    assert parse_args(["-r", "r", "a"]) == {["a"], [recipient: "r"]}
    assert parse_args(["--recipient", "r", "a"]) == {["a"], [recipient: "r"]}
  end

  test "process/1 when adding a new password" do
    process({["add", "foo"], []})
    assert File.exists?(PW.root_dir <> "foo")
  end

  test "process/1 when removing a password" do
    process({["add", "foo"], []})
    assert File.exists?(PW.root_dir <> "foo")
    process({["rm", "foo"], []})
    refute File.exists?(PW.root_dir <> "foo")
  end
end
