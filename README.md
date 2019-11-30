[![Build Status](https://travis-ci.com/crystallabs/term_app.svg?branch=master)](https://travis-ci.com/crystallabs/term_app)
[![Version](https://img.shields.io/github/tag/crystallabs/term_app.svg?maxAge=360)](https://github.com/crystallabs/term_app/releases/latest)
[![License](https://img.shields.io/github/license/crystallabs/term_app.svg)](https://github.com/crystallabs/term_app/blob/master/LICENSE)

# Tput

Term_app is a minimal functional term/console app environment for Crystal.

It is closely related to shards [Terminfo](https://github.com/crystallabs/terminfo) and
[Tput](https://github.com/crystallabs/tput):

Terminfo parses terminfo files into instances of `Terminfo::Data` or custom classes.

Tput uses Terminfo data and additional methods to configure itself for outputting correct terminal sequences.

Term_app uses Tput and implements a completely usable term/console environment.
It sets up event handlers, keys and mouse listeners, and everything else needed to
provide a minimal working application.

It is implemented natively and does not depend on ncurses or other external library.

## Installation

Add the dependency to `shard.yml`:

```yaml
dependencies:
  term_app:
    github: crystallabs/term_app
    version: 0.1.0
```

## Usage in a nutshell

Here is a basic example that starts the application, waits for keypresses or
pasted data, prints the received content, and then fixes the cursor at screen
character x = 10, y = 10:

```crystal
require "term_app"

my = TermApp::Data.new

my.input.on(TermApp::DataEvent) { |e|
  my.tput.print e.data[...e.len]
  my.tput.sety 10
  my.tput.setx 10
}

sleep 10
```

## API documentation

Run `crystal docs` as usual, then open file `docs/index.html`.

Also, see examples in the directory `examples/`.

## Testing

Run `crystal spec` as usual.

Also, see examples in the directory `examples/`.

## Thanks

* All the fine folks on FreeNode IRC channel #crystal-lang and on Crystal's Gitter channel https://gitter.im/crystal-lang/crystal

## Other projects

List of interesting or similar projects in no particular order:

- https://github.com/crystallabs/crysterm - Complete term/console toolkit for Crystal
