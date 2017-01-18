#!/usr/bin/env bash
srcdir=`pwd`
_target="x64"

cd "${srcdir}"/electron
LDFLAGS="${LDFLAGS} -Wl,-z,noexecstack"
script/bootstrap.py --verbose \
                  --target_arch=${_target} \
                  --clang_dir=/usr \
                  --build_libchromiumcontent \
                  --defines="${_chromium_flags[*]}"
script/build.py -c Release