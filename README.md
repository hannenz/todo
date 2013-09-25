# todo

This is a [todo.txt](http://todotxt.com) app for [elementary OS](http://elementaryos.org).

It is using elementary's granite library.

## Build

```
$ cd todo
$ mkdir build && cd build
$ cmake -DCMAKE_INSTALL_PREFIX=/usr/ ../
$ make
# make install
```
## Use

After `todo` has been properly installed it is available from the applications menu (`slingshot`). Alternatively launch todo from the command line. Open up a terminal window and type

```
$ todo [file]
```

`Todo` doesn't have any options but you may specify a filename.

`Todo` will look for an existing todo.txt file in the following order and will open the first existing file, it encounters:

- Filename given as command line argument

- `$HOME/Dropbox/todo/todo.txt`

- `$HOME/Dropbox/todo.txt`

- `$HOME/todo.txt`


