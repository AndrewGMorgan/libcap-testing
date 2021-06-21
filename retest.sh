#!/bin/bash

HASH="$(git ls-remote --head git://git.kernel.org/pub/scm/libs/libcap/libcap.git|awk '{print $1}')"
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
git clone git://git.kernel.org/pub/scm/libs/libcap/libcap.git
cd clone || exit 1
# redefine HASH from actual copy - avoid race condition.
HASH=$(git rev-parse HEAD)
if [[ "${HASH}" = "$(cat last-hash 2>/dev/null)" ]]; then
  echo "no change since last clone request"
  exit 0
fi

echo "should build and test clone ${HASH}"
make FAKEROOT="${FAKEROOT}" all test install distclean

cd "${FAKEROOT}"
ls -lRt