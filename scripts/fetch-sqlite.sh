#!/bin/sh
# Downloads one SQLite amalgamation, checks it against the digest sqlite.org
# publishes for it, and unpacks sqlite3.c and sqlite3.h into a directory.
#
# Usage:
#   scripts/fetch-sqlite.sh <url> <sha3-256> <destination-dir>
set -eu

url=${1:?usage: fetch-sqlite.sh <url> <sha3-256> <dest-dir>}
want=${2:?usage: fetch-sqlite.sh <url> <sha3-256> <dest-dir>}
dest=${3:?usage: fetch-sqlite.sh <url> <sha3-256> <dest-dir>}

die() { echo "fetch-sqlite: $*" >&2; exit 1; }

sha3_256() {
    if openssl dgst -sha3-256 -r "$1" 2>/dev/null | grep -qE '^[0-9a-f]{64} '; then
        openssl dgst -sha3-256 -r "$1" | cut -d' ' -f1
    else
        die "no SHA3-256 tool found: need openssl 1.1.1+"
    fi
}

fetch() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1"
    else
        die "neither curl nor wget is installed"
    fi
}

command -v unzip >/dev/null 2>&1 || die "unzip is not installed"

mkdir -p "$dest"
tmp="$dest/.incoming"
rm -rf "$tmp"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT INT TERM

zip="$tmp/amalgamation.zip"

echo "fetch-sqlite: downloading $url"
fetch "$url" "$zip" || die "download failed: $url"

got=$(sha3_256 "$zip")
if [ "$got" != "$want" ]; then
    die "SHA3-256 mismatch for $url
   expected $want
   actual   $got
   Nothing has been unpacked. Either the download was corrupted -- try
   again -- or the pinned digest in the makefile no longer describes what
   sqlite.org is serving, which is worth understanding before building."
fi
echo "fetch-sqlite: SHA3-256 $got verified"

unzip -q -o "$zip" -d "$tmp" || die "could not unpack $zip"

for f in sqlite3.c sqlite3.h; do
    found=$(find "$tmp" -name "$f" -type f | head -1)
    [ -n "$found" ] || die "$f is not in the archive"
    cp "$found" "$dest/$f"
done

echo "fetch-sqlite: unpacked sqlite3.c and sqlite3.h into $dest"
