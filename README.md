PW
==

PW is a personal, GPG-based, password manager.

### Usage

   # Get a prompt to add a new password named google.com.
   pw add google.com
   
   # Print google.com password to stdout.
   pw get google.com
   
   # Copy google.com password to clipboard.
   pw copy google.com
   
   # Get a prompt to edit google.com password.
   pw edit google.com
   
   # Generate a random new password named amazon.com
   pw generate amazon.com
   
   # List all passwords
   pw list

### Inspiration

* Internal project for password management used by [Stripe](https://stripe.com).
* [pw](https://github.com/nelhage/pw) by [nelhage](https://twitter.com/nelhage).
