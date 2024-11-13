#!/usr/bin/env sh

## NB: this is an sh script, not bash. We can't assume a new host will have an
## up to date bash installed.

set -e

# Where to install binaries.
PREFIX="${HOME}/.local"

EMAIL="${EMAIL:-}"
KEYFILE="${KEYFILE:-${HOME}/.ssh/id_ed25519_github}"
SCRIPTSDIR="${SCRIPTSDIR:-${HOME}/scripts}"

JOBS="${JOBS:-$(nproc)}"

SSHCONFIG="${SSHCONFIG:-${HOME}/.ssh/config}"

GITHOMEURL="${GITHOMEURL:-git@github.com:fshaked/home-git-repo.git}"
GITSCRIPTSURL="${GITSCRIPTSURL:-git@github.com:fshaked/scripts.git}"

MYDIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# Read _*_version variables
. "${MYDIR}/versions.sh"

make_version="${make_version:-${_make_version}}"
bash_version="${bash_version:-${_bash_version}}"
emacs_version="${emacs_version:-${_emacs_version}}"
fzf_version="${fzf_version:-${_fzf_version}}"

MAKEBASE="${MAKEBASE:-make-${make_version}}"
MAKEURL="${MAKEURL:-https://ftp.gnu.org/gnu/make/}"

BASHBASE="${BASHBASE:-bash-${bash_version}}"
BASHURL="${BASHURL:-https://ftp.gnu.org/gnu/bash/}"

EMACSBASE="${EMACSBASE:-emacs-${emacs_version}}"
EMACSURL="${EMACSURL:-https://ftp.gnu.org/gnu/emacs/}"

FZFBASE="fzf-${fzf_version}-linux_amd64"
FZFURL="https://github.com/junegunn/fzf/releases/download/${fzf_version}/${FZFBASE}.tar.gz"

github_keys() {
  if [ ! "${EMAIL}" ]; then
    printf 'Error: EMAIL is not set\n' >&2
    exit 2
  fi

  if [ -f "${KEYFILE}" ]; then
    printf 'Warning: file already exists: %s\n' "${KEYFILE}" >&2
    printf 'Set KEYFILE to change the file.\n' >&2
  fi

  if grep -q '^Host github.com$' "${SSHCONFIG}" >/dev/null 2>/dev/null ; then
    printf 'Warning: github.com is already in %s\n' "${SSHCONFIG}" >&2
  fi

  mkdir -pm 0700 "${HOME}/.ssh"
  ssh-keygen -t ed25519 -C "${EMAIL}" -f "${KEYFILE}"
  ! [ -f "${SSHCONFIG}" ] || echo >> "${SSHCONFIG}"
  cat >> "${SSHCONFIG}" <<EOF
Host github.com
  IdentityFile "${KEYFILE}"
EOF

  printf "Now go to 'https://github.com/settings/keys', add a new SSH key, and paste the following into the key field:\n"
  cat "${KEYFILE}.pub"
  printf "Then run 'bootstrap.sh clone_home NEW_BRANCH'\n"
  printf "followed by 'bootstrap.sh clone_scripts'.\n"

}

# $1 should be a name for the new branch (e.g. 'work-laptop')
clone_home() {
  local new_branch="$1"
  if [ -z "${new_branch}" ]; then
    printf -- 'Error: clone_home expects a NEW_BRANCH\n' >&2
    exit 2
  fi

  git clone "${GITHOMEURL}" --separate-git-dir "${HOME}/.home-git-repo" "${HOME}"
  git -C "${HOME}" checkout -b "${new_branch}"

  mv -f "${HOME}"/.git "${HOME}"/.dot-git

  printf "Now run 'bootstrap.sh clone_scripts'.\n"
}

clone_scripts() {
  git clone "${GITSCRIPTSURL}" "${SCRIPTSDIR}"
  printf "Now go to '%s' and run 'make install-bash'.\n" "${SCRIPTSDIR}"
}

install_make() {
  [ -f "${MAKEBASE}.tar.gz" ] || wget "${MAKEURL}${MAKEBASE}.tar.gz"
  [ -d "${MAKEBASE}" ] || tar -zxf "${MAKEBASE}.tar.gz"

  cd "${MAKEBASE}"
  ./configure --prefix="${PREFIX}" || return
  make -j "${JOBS}" || return
  make install
}

install_bash() {
  [ -f "${BASHBASE}.tar.gz" ] || wget "${BASHURL}${BASHBASE}.tar.gz"
  [ -d "${BASHBASE}" ] || tar -zxf "${BASHBASE}.tar.gz"

  cd "${BASHBASE}"
  ./configure --prefix="${PREFIX}" || return
  make -j "${JOBS}" || return
  make install
}

install_fzf() {
  [ -f "${FZFBASE}.tar.gz" ] || wget "${FZFURL}"
  tar -zxf "${FZFBASE}.tar.gz"
  mv fzf "${PREFIX}/bin/"
  # It's also very easy to build fzf:
  # # first, if needed (try: `go version`), download go-lang:
  # # wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz
  # # tar -zxf go1.21.1.linux-amd64.tar.gz
  # # export PATH="${PWD}/go/bin:${PATH}"
  # git clone https://github.com/junegunn/fzf.git
  # make -C fzf || return
  # make -C fzf install || return
  # cp fzf/bin/fzf "${PREFIX}/bin/"
}

install_emacs() {
  [ -f "${EMACSBASE}.tar.gz" ] || wget "${EMACSURL}${EMACSBASE}.tar.gz"
  [ -d "${EMACSBASE}" ] || tar -zxf "${EMACSBASE}.tar.gz"

  cd "${EMACSBASE}"
  ./configure --prefix="${PREFIX}"
  make -j "${JOBS}"
  make install
}

gen_versions_file() {
  dpkg-query --show --showformat='${Package},${source:Upstream-Version}\n' make bash fzf emacs 2>/dev/null | \
    sed -E 's/\+.*//' | \
    while IFS=, read -r package version; do
      printf '_%s_version="%s"\n' "${package}" "${version}"
    done > "${MYDIR}/versions.sh"
}

help() {
  cat <<EOF
Available commands:
github_keys    Generate and install ssh keys for GitHub.
               Required:
                 EMAIL - must be set to some email.
clone_home NEW_BRANCH
clone_scripts
install_bash
install_make
install_fzf
install_emacs
gen_versions_file  Recreate versions.sh with versions from dpkg on the current host.
EOF
}

main() {
  case "${1:-}" in
    github_keys) "$@" ;;
    clone_home) "$@" ;;
    clone_scripts) "$@" ;;
    install_bash) "$@" ;;
    install_make) "$@" ;;
    install_fzf) "$@" ;;
    install_emacs) "$@" ;;
    gen_versions_file) "$@" ;;
    help) "$@" ;;
    *)
      printf 'Error: unknown command: %s\n' "$1" >&2
      help >&2
      exit 2
      ;;
  esac
}

main "$@"
