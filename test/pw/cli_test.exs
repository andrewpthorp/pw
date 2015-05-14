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

    # Make sure test/data is clear for each test (brittle)
    File.rm_rf("test/data")
    File.mkdir_p("test/data")
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

  # TODO: Seriously need to consider if I still want these tests.
  if false do
    test "adding a new password" do
      process({["add", "foo"], []})
      assert File.exists?(PW.root_dir <> "foo")
    end

    test "renaming a password" do
      process({["add", "old"], []})
      assert File.exists?(PW.root_dir <> "old")

      process({["mv", "old", "new"], []})
      refute File.exists?(PW.root_dir <> "old")
      assert File.exists?(PW.root_dir <> "new")
    end

    test "adding a nested password" do
      process({["add", "foo/bar"], []})
      assert File.exists?(PW.root_dir <> "foo/bar")
    end

    test "removing a password" do
      process({["add", "foo"], []})
      assert File.exists?(PW.root_dir <> "foo")
      process({["rm", "foo"], []})
      refute File.exists?(PW.root_dir <> "foo")
    end

    # TODO: testing list/get is brittle and depends on my gpg key. This is fine
    # for now, but I need a real approach for this.
    test "listing passwords returns an array" do
      process({["add", "foopass"], []})
      assert process({["ls"], []}) == ["foopass"]
    end

    @tag :real_gpg
    test "getting password returns the contents" do
      process({["add", "foopass"], [recipient: "andrewpthorp@gmail.com"]})
      assert process({["get", "foopass"], []}) == ["Contents of foopass:", "username: foo", "password: bar"]
    end
  end
end
