#!/bin/bash

echo "some environment setup"

uname -a
gcc --version
go version
id
pwd

URL=git://git.kernel.org/pub/scm/libs/libcap/libcap.git

HASH="$(git ls-remote --head ${URL}|awk '{print $1}')"
echo "should build and test clone: ${HASH}"
if [[ -z "${HASH}" ]]; then
  echo "unable to determine hash value of upstrem"
  exit 1
fi
if [[ "${HASH}" = "$(cat last-hash 2>/dev/null)" ]]; then
  echo "no change since last clone request"
  exit 0
fi

mkdir built
FAKEROOT="$(pwd)/built"
mkdir clone
cd clone || exit 1
git clone "${URL}"
cd libcap || exit 1
# redefine HASH from actual copy - avoid race condition.
HASH=$(git rev-parse HEAD)
if [[ "${HASH}" = "$(cat ../last-hash 2>/dev/null)" ]]; then
  echo "no change since last clone request"
  exit 0
fi
cd ../..

echo "should build and test clone ${HASH}"
echo "${HASH}" > last-hash
ls -l

cd clone/libcap
make FAKEROOT="${FAKEROOT}" all test install distclean || exit 1

cd "${FAKEROOT}"
ls -lRt
