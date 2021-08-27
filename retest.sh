#!/bin/bash

echo "some environment setup"

# Clean up after last invocation. Github does this automatically, but
# testing from my sandbox does not.
rm -rf clone built

uname -a
gcc --version
go version
id
pwd
ls -l

URL=git://git.kernel.org/pub/scm/libs/libcap/libcap.git

HASH="$(git ls-remote --head ${URL}|awk '{print $1}')"
LASTHASH="$(cat last-hash 2>/dev/null)"
echo "should build and test clone: ${HASH}"
if [[ -z "${HASH}" ]]; then
  echo "unable to determine hash value of upstrem"
  exit 1
fi
if [[ "${HASH}" = "${LASTHASH}" ]]; then
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
if [[ "${HASH}" = "${LASTHASH}" ]]; then
  echo "no change since last clone request"
  exit 0
fi
cd ../..

echo "should build and test clone for all commits after"
echo "  ${LASTHASH} ... to ..."
echo "  ${HASH}"

echo "${HASH}" > last-hash
git config user.email "morgan@kernel.org"
git config user.name "Andrew's Robot"

cd clone/libcap
git checkout -b rebuild 

for h in $(git log --reverse HEAD..."${LASTHASH}" --pretty=format:"%H"); do
    git reset --hard "${h}"
    rm -rf "${FAKEROOT}/*"
    STATUS="PASS"
    make FAKEROOT="${FAKEROOT}" clean all test sudotest install || STATUS="FAIL"
    (git log -1 --pretty=format:"-  %cd [%h](https://git.kernel.org/pub/scm/libs/libcap/libcap.git/commit/?id=%H): ${STATUS}" ; echo) >> ../../build.md
done

cd "${FAKEROOT}"
ls -lRt

cd ..
(cat README.head ; echo "## Current build status: ${STATUS}" ; tail -10 build.md) > README.md
git status
git add last-hash build.md README.md
git commit -m "upstream libcap updated just before $(date)"
git status
git push || exit 1

echo "Most recent build (${h}) was a ${STATUS}"
if [[ "${STATUS}" = "FAIL" ]]; then
    exit 1
fi
