defmodule PW.FileUtils do
  import PW.GPG, only: [encrypt: 2]

  @doc """
  Create a temporary file with `text` as the starting contents of the file.

  Returns the fully qualified filename.
  """
  def create(text) do
    filename = System.tmp_dir! <> rand_string(6)
    File.write!(filename, text)

    filename
  end

  @doc """
  Opens `filename` in `mvim` (must be in your path).

  Returns the same `filename` you pass in.
  """
  def edit(filename) do
    # HACK: Don't use mvim directly, but `vim` doesn't work so $EDITOR is out
    # unless I figure out why it does not work.
    {"", 0} = System.cmd("mvim", [filename])

    filename
  end

  @doc """
  Reads the contents of `tmp_filename`, removes coments and encrypts it, then
  writes the results to `filename` and removes `tmp_filename`.

  Returns :ok or raises an exception (from `File.write!` or `File.rm!`).
  """
  def finalize!(tmp_filename, filename, opts) do
    ciphertext = File.read!(tmp_filename) |> remove_comments |> encrypt(opts)
    File.write!(PW.root_dir(opts) <> filename, ciphertext)
    File.rm!(tmp_filename)

    :ok
  end

  defp remove_comments(text) do
    String.split(text, "\n")
    |> Enum.reject(fn(x) -> String.at(x, 0) == "#" end)
    |> Enum.join("\n")
  end

  defp rand_string(num_chars) do
    :crypto.rand_bytes(num_chars) |> :base64.encode
  end

end
