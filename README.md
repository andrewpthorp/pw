PW
==

PW is a personal, GPG-based, password manager.

### Usage

```shell

# Get a prompt to add a new password named google.com.
$ pw add google

# List all passwords
$ pw ls | grep google

# Print google.com password to stdout.
$ pw get google

# Rename a password.
$ pw mv google personal/google.com

# Remove a password
$ pw rm personal/google.com

# Get help
$ pw -h
```

A typical flow for me looks like the following:

```
$ pw add personal/google.com
Encrypting personal/google.com to andrewpthorp@gmail.com.
Type the contents of personal/google.com, end with a blank line:
username: andrewpthorp@gmail.com
password: mypass
[enter]

# Two weeks later, when I can't remember what the password was stored as.
$ pw ls | grep google
personal/google.com

$ pw get personal/google.com
Contents of personal/google.com:
username: andrewpthorp@gmail.com
password: mypass
```

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
