#!/bin/bash

mkdir clone
git clone git://git.kernel.org/pub/scm/libs/libcap/libcap.git
cd clone || exit 1
HASH=$(git rev-parse HEAD)
cd ..
if [[ -z "${HASH}" ]]; then
  echo "unable to determine hash value of clone"
  exit 1
fi
if [[ "${HASH}" = "$(cat last-hash 2>/dev/null)" ]]; then
  echo "no change since last clone request"
  exit 0
fi
echo "should build and test clone ${HASH}"
