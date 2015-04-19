defmodule PWTest do
  use ExUnit.Case

  test "root_dir/0" do
    Application.put_env(:pw, :directory, "nashville")
    assert PW.root_dir == Path.expand("nashville") <> "/"
  end

  test "root_dir/1 returns directory if you pass it" do
    assert PW.root_dir([directory: "/foo/bar"]) == "/foo/bar/"
  end

  test "recipient/0" do
    Application.put_env(:pw, :recipient, "foo@bar.com")
    assert PW.recipient == "foo@bar.com"
  end

  test "recipient/1 returns recipient if you pass it" do
    assert PW.recipient([recipient: "foobar"]) == "foobar"
  end

  test "io/0" do
    Application.put_env(:pw, :io, IO)
    assert PW.io == IO
  end
end
