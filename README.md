# bootstrap

A small public script for generating GitHub keys, cloning the private scripts repo,
and building some tools from source.

```shell
git clone https://github.com/fshaked/bootstrap.git
./bootstrap/bootstrap.sh github_keys
```

# Using gsrc to build missing GNU tools

## Links

- [Homepage](https://www.gnu.org/software/gsrc/gsrc.html)
- [List of packages](https://www.gnu.org/software/gsrc/package-list.html)
- [Manual](https://www.gnu.org/software/gsrc/manual/gsrc.html)

## Installing in user $HOME on top of busybox

```shell
git clone --depth=1  https://https.git.savannah.gnu.org/git/gsrc.git
cd gsrc/
./bootstrap
./configure --prefix=$HOME/gnu
source ./setup.sh

# Might give a warning about miggin makeinfo and exit with 127
# That seems to be ok.
make install
```

```shell
echo 'source "$HOME/gsrc/setup.sh"' >> $HOME/.bashrc
```

Build `xz` without installing it, as the install target uses `find` options that
might not be supported by the installed one:

```shell
make -C pkg/other/xz build
```

Build `findutils`, with augmented `PATH` and `LD_LIBRARY_PATH` to use the built
(but not installed) `xz`. This also has to be done in two steps: first build
`findutils`, than use it to install itself.

```shell
PATH="$(echo "$HOME"/gnu/packages/xz-*/bin)":"$PATH" LD_LIBRARY_PATH="$(echo "$HOME"/gnu/packages/xz-*/lib)":"$LD_LIBRARY_PATH" make -C pkg/gnu/findutils build
PATH="$(echo "$HOME"/gnu/packages/xz-*/bin)":"$(echo "$HOME"/gnu/packages/findutils-*/bin)":"$PATH" LD_LIBRARY_PATH="$(echo "$HOME"/gnu/packages/xz-*/lib)":"$LD_LIBRARY_PATH" make -C pkg/gnu/findutils install
```

Finish installing `xz`:
```
make -C pkg/other/xz install
```

Build coreutils (the `man1_MANS=` is required when the system perl is missing
modules that are used when generating man pages), and other basic tools:
```shell
# The order of building is important
make -C pkg/gnu/coreutils install man1_MANS=
make -C pkg/other/lzip install
make -C pkg/gnu/patch install
```

Build make:
```shell
make -C pkg/gnu/make install
```

Build bash:
```shell
make -C pkg/gnu/bash install
```
