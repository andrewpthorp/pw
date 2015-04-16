defmodule PWTest do
  use ExUnit.Case

  test "root_dir/0" do
    Application.put_env(:pw, :directory, "nashville")
    assert PW.root_dir == Path.expand("nashville") <> "/"
  end

  test "recipient/0" do
    Application.put_env(:pw, :recipient, "foo@bar.com")
    assert PW.recipient == "foo@bar.com"
  end

  test "io/0" do
    Application.put_env(:pw, :io, IO)
    assert PW.io == IO
  end
end
