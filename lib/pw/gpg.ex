defmodule PW.GPG do
  alias Porcelain.Result
  import PW, only: [root_dir: 1, recipient: 1]

  @moduledoc """
  The core of `PW.GPG` is `decrypt` and `encrypt`. All things pertaining to
  encrypting and decrypting content with `gpg` is handled here.
  """

  @doc """
  Decrypt the contents of a file, shelling out to `gpg` on your system and
  returning the result.
  """
  def decrypt(filename, opts) do
    Porcelain.shell("gpg --no-tty -d '#{root_dir(opts) <> filename}'")
  end

  @doc """
  Encrypt plaintext, shelling out to `gpg` on your system and returning the
  result.
  """
  def encrypt(plaintext, opts) do
    Porcelain.shell("echo '#{plaintext}' | gpg --no-tty -aer #{recipient(opts)}")
    |> output
  end

  defp output(%Result{out: output}), do: output

end
