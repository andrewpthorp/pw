defmodule PW.UtilsTest do
  use ExUnit.Case, async: false
  import PW.Utils

  test "rand_string returns a unique string" do
    assert rand_string(5) != rand_string(5)
  end

  test "rand_string returns the right length" do
    assert String.length(rand_string(5)) == 5
    assert String.length(rand_string(10)) == 10
  end
end
