PW
==

PW is a personal, GPG-based, password manager.

### Usage

    # Get a prompt to add a new password named google.com.
    $ pw add google.com

    # Print google.com password to stdout.
    $ pw get google.com

    # List all passwords
    $ pw list

    # Remove a password
    $ pw rm google.com

A typical flow for me looks like the following:

    $ pw add google-personal
    Encrypting google-personal to andrewpthorp@gmail.com.
    Type the contents of google-personal, end with a blank line:
    username: andrewpthorp@gmail.com
    password: mypass
    [enter]

    $ pw get google-personal
    Contents of google-personal:
    username: andrewpthorp@gmail.com
    password: mypass

Use `pw -h` to see all available options.

### Configuration

You can create a file `~/.pw` with some configuration.

    # ~/.pw
    directory=~/pw
    recipient=<your_gpg_key>

`directory` is where the passwords will be stored, `recipient` is what is passed
to `gpg` as the `-r` for encryption.

### Inspiration

* Internal project for password management used by [Stripe](https://stripe.com).
* [pw](https://github.com/nelhage/pw) by [nelhage](https://twitter.com/nelhage).
