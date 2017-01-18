#!/usr/bin/env bash
srcdir=`pwd`
_target="x64"
_chromium_flags=('fastbuild=2'
                 'host_clang=0'
                 'linux_use_bundled_binutils=0'
                 'linux_use_bundled_gold=0'
                 'release_extra_cflags="-O3"'
                 'remove_webcore_debug_symbols=1'
                 'use_gconf=0'
                 'use_sysroot=0'
                 'use_system_expat=1'
                 'use_system_ffmpeg=1'
                 'use_system_flac=1'
                 'use_system_re2=1'
                 'use_system_snappy=1'
                 'use_system_yasm=1'
                 'use_system_zlib=1'
                 'werror=""'  # required by bundled ICU and i686 build
                )

cd "${srcdir}"/electron
script/bootstrap.py --verbose \
                  --target_arch=${_target} \
                  --clang_dir=/usr \
                  --build_libchromiumcontent \
                  --defines="${_chromium_flags[*]}"
script/build.py -c Release