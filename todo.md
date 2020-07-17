# spot - todo

- `spot sync --interactive` should have an interface more similar to
  mercurial's interactive, where I can select each row to be either
  from (f), to (t), best (y), or no (n). Something like, kakoune or
  $EDITOR opens with the following text:

    [ ] rofi -> .config/rofi.fasi
    [ ] sway -> .config/rofi.fasi
    [ ] tmux -> .config/rofi.fasi

  and the user fills in the [ ] with [f/t/y/n] depending on their choice

- after sync-ing, copy file timestamps not only to things inside of
  $SPOT_FILES, but also to the destination of each of those files, so
  a second sync command triggers nothing.
