defmodule PW.CLI do
  alias   Porcelain.Result

  @moduledoc """
  Usage: pw [options] <command> [args]

  Options:
      -h, --help                        Display this message
      -r, --recipient REC               Specify the gpg recipient <REC> to encrypt the password to
      -d, --directory DIR               Write passwords to / read passwords from <DIR>
      -v, --version                     Print the version of the app

  Commands:
      l, ls                             List all passwords by name
      a, add <password>                 Add a new password, named <password>
      g, get <password>                 Get <password> and print to STDOUT
      e, edit <password>                Edit <password> with mvim
      r, rm <password>                  Delete <password>
      m, mv <password> <new_password>   Move <password> to <new_password>
  """

  def main(argv) do
    parse_config
    argv
      |> parse_args
      |> process
      |> Enum.join("\n")
      |> PW.io.puts
  end

  @switches [help: :boolean, version: :boolean]
  @aliases [h: :help, r: :recipient, d: :directory, v: :version]

  @doc """
  Parse a file at ~/.pw to set env variables.
  """
  def parse_config do
    case File.read(Path.expand(Application.get_env(:pw, :config_file))) do
      {:ok, ""}     -> :ok
      {:ok, config}   ->
        String.strip(config)
        |> String.split("\n")
        |> Enum.map(&(String.split(&1, "=")))
        |> Enum.each(fn [k, v] -> Application.put_env(:pw, String.to_atom(k), v) end)

      {:error, _err}  -> :ok
    end
  end

  @doc """
  Use `OptionParser` to parse arguments.

  If `-h`, `--help`, or an unknown command is in argv, return :usage. If not,
  return a tuple in the format {[command, optional_arg], flags}.
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: @switches, aliases: @aliases)

    case parse do
      {[version: true], _, _}             -> :version
      {[help: true], _, _}                -> :usage
      {flags, [command, arg], _}          -> {[command, arg], flags}
      {flags, [command, arg1, arg2], _}   -> {[command, arg1, arg2], flags}
      {flags, [command], _}               -> {[command], flags}
      _                                   -> :usage
    end
  end

  @doc """
  List all passwords.

  Print the name of every file in `root_dir` to STDOUT.
  """
  def process({["l"], opts}), do: process({["ls"], opts})
  def process({["ls"], opts}) do
    fetch_passwords(PW.root_dir(opts), PW.root_dir(opts))
  end

  @doc """
  Print a password to STDOUT.

  Validate `filename` exists in `root_dir`, then decrypt it and write the
  plaintext to STDOUT.
  """
  def process({["g", filename], opts}), do: process({["get", filename], opts})
  def process({["get", filename], opts}) do
    validate_file_exists!(filename, opts)

    case PW.GPG.decrypt(filename, opts) do
      %Result{out: results, status: 0} ->
        ["Contents of #{filename}:"] ++ String.split(String.strip(results), "\n")
      %Result{err: _err} ->
        error("GPG decryption failed.")
    end
  end

  @doc """
  Add a new password to the filesystem.

  Encrypt the contents of STDIN to the gpg key for `recipient`. The ciphertext
  will then be written to disk at `root_dir <> filename`.
  """
  def process({["a", filename], opts}), do: process({["add", filename], opts})
  def process({["add", filename], opts}) do
    validate_recipient_set!(opts)
    create_directory(filename, opts)

    """
    Encrypting #{filename} to #{PW.recipient(opts)}.
    Type the contents of #{filename}, end with a blank line:
    """
    |> String.strip
    |> PW.io.puts

    create_tmpfile
    |> finalize_tmpfile(filename, opts)

    ["Added #{filename}."]
  end

  def process({["e", filename], opts}), do: process({["edit", filename], opts})
  def process({["edit", filename], opts}) do
    validate_recipient_set!(opts)
    validate_file_exists!(filename, opts)

    case PW.GPG.decrypt(filename, opts) do
      %Result{out: results, status: 0} ->
        create_tmpfile(results)
        |> finalize_tmpfile(filename, opts)

        ["Updated #{filename}."]
      %Result{err: _err} ->
        error("GPG decryption failed.")
    end
  end

  @doc """
  Remove a password.

  Validate `filename` exists in `root_dir`, then delete `filename` from
  `root_dir`.
  """
  def process({["r", filename], opts}), do: process({["rm", filename], opts})
  def process({["rm", filename], opts}) do
    validate_file_exists!(filename, opts)

    File.rm!(PW.root_dir(opts) <> filename)

    ["Deleted #{filename}."]
  end

  @doc """
  Rename/move a password.

  Validate `filename` exists in `root_dir`, then move it to `new_location`.
  """
  def process({["m", filename, new_filename], opts}), do: process({["mv", filename, new_filename], opts})
  def process({["mv", filename, new_filename], opts}) do
    validate_file_exists!(filename, opts)
    create_directory(new_filename, opts)

    :file.rename(PW.root_dir(opts) <> filename, PW.root_dir(opts) <> new_filename)

    ["Moved #{filename} to #{new_filename}."]
  end

  @doc """
  Use `process(:usage)` to get help.
  """
  def process({["h"], _opts}), do: process({["help"], _opts})
  def process({["help"], _opts}), do: process(:usage)


  @doc """
  Print usage information to STDOUT.
  """
  def process(:usage) do
    PW.io.puts @moduledoc
    System.halt(0)
  end

  @doc """
  Print version to STDOUT.
  """
  def process(:version) do
    PW.io.puts PW.version
    System.halt(0)
  end

  @doc """
  If the command that is passed in is not a valid command, print the usage
  information to STDOUT.
  """
  def process(args) do
    command = elem(args, 0) |> Enum.at(0)
    error("unknown command: #{command}. Use -h to get help.")
  end

  # Generates a temporary file name, launches `mvim` to create it.
  defp create_tmpfile(contents \\ "") do
    tmpfile = System.tmp_dir! <> :crypto.rand_bytes(6)
    File.write!(tmpfile, contents)

    # HACK: Don't use mvim directly, but `vim` doesn't work so $EDITOR is out
    # unless I figure out why it does not work.
    {"", 0} = System.cmd("mvim", [tmpfile])

    tmpfile
  end

  # Takes a `tmpfile`, encrypts it, and moves it to `filename`.
  defp finalize_tmpfile(tmpfile, filename, opts) do
    File.read!(tmpfile)
    |> PW.GPG.encrypt(opts)
    |> write_to_file(filename, opts)

    File.rm!(tmpfile)
  end

  # Takes some `ciphertext` and writes it to `filename` in `root_dir`. It will
  # overwrite `filename` in `root_dir` if it already exists.
  defp write_to_file(ciphertext, filename, opts) do
    File.write!(PW.root_dir(opts) <> filename, ciphertext)
  end

  # Validate `filename` exists in `root_dir`, exit program with a status of 1 if
  # it does not.
  defp validate_file_exists!(filename, opts) do
    if !File.exists?(PW.root_dir(opts) <> filename) do
      error("#{PW.root_dir(opts) <> filename} does not exist.")
    end
  end

  # Validate `recipient` is set to something. This does not check that it is a
  # valid GPG recipient.
  defp validate_recipient_set!(opts) do
    if PW.recipient(opts) == nil do
      error("recipient is not set.")
    end
  end

  # In order to allow passwords in nested directories, we have to make sure the
  # entire directory structure exists.
  defp create_directory(filename, opts) do
    PW.root_dir(opts) <> filename
    |> String.split("/")
    |> List.delete_at(-1)
    |> Enum.join("/")
    |> File.mkdir_p
  end

  # Get all passwords in a `path`. `base_path` is stripped from each of the
  # filenames at the end. This lets us preserve the partial path for nested
  # passwords, but remove the base path (PW root).
  defp fetch_passwords(path, base_path) do
    path = Path.expand(path) <> "/"
    File.ls!(path)
    |> Enum.map(fn x -> if File.dir?(path <> x), do: fetch_passwords(path <> x, base_path), else: path <> x end)
    |> List.flatten
    |> Enum.map(&String.replace(&1, base_path, ""))
  end

  # Print an appropriate, red error `msg`.
  defp error(msg) do
    error(msg, 1)
  end

  defp error(msg, status) do
    IO.ANSI.red <> IO.ANSI.underline <> "Error" <> IO.ANSI.no_underline <> ": #{msg}" <> IO.ANSI.reset |> IO.puts
    System.halt(status)
  end
end
