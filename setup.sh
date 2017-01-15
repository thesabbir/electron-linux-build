#!/usr/bin/env bash
srcdir=`pwd`
_chromiumver=53.0.2785.143
arch=('i686' 'x86_64')
pkgver="1.4.14"
src="https://github.com/electron/electron.git"
_chromium_flags=('fastbuild=2'
                 'host_clang=0'
                 'linux_use_bundled_binutils=0'
                 'linux_use_bundled_gold=0'
                 'release_extra_cflags="-O3"'
                 'remove_webcore_debug_symbols=1'
                 'use_gconf=0'
                 'use_gtk3=1'
                 'use_sysroot=0'
                 'use_system_expat=1'
                 'use_system_ffmpeg=1'
                 'use_system_flac=1'
                 'use_system_harfbuzz=1'
                 'use_system_jsoncpp=1'
                 'use_system_libevent=1'
                 'use_system_libjpeg=1'
                 'use_system_libpng=1'
                 'use_system_libvpx=1'
                 'use_system_libwebp=1'
                 'use_system_libxml=1'
                 'use_system_libxslt=1'
                 'use_system_re2=1'
                 'use_system_snappy=1'
                 'use_system_yasm=1'
                 'use_system_zlib=1'
                 'werror=""'  # required by bundled ICU and i686 build
                )

echo "Cloning electron..."
git clone -b v${pkgver} ${src} electron --depth=1
cd electron
patch -Np1 -i "${srcdir}"/patches/gtk3-menu-bar.patch
patch -Np1 -i "${srcdir}"/patches/gtk3-warnings.patch
patch -Np1 -i "${srcdir}"/patches/use-system-clang.patch
patch -Np1 -i "${srcdir}"/patches/use-system-libraries-in-node.patch
patch -Np1 -i "${srcdir}"/patches/use-system-ninja.patch
patch -Np1 -i "${srcdir}"/patches/use-system-ffmpeg.patch
patch -Np1 -i "${srcdir}"/patches/dont-update-submodules.patch
patch -Np1 -i "${srcdir}"/patches/dont-use-sysroot.patch
patch -Np1 -i "${srcdir}"/patches/dont-bootstrap-libchromiumcontent.patch
patch -Np1 -i "${srcdir}"/patches/allow-i686.patch
for m in boto breakpad brightray native_mate node requests; do
    git submodule init vendor/${m}
done
git submodule update

cd "${srcdir}"/electron/vendor/breakpad
git submodule init src
git submodule update

cd "${srcdir}"/electron/vendor/brightray
patch -Np1 -i "${srcdir}"/patches/brightray-dont-update-submodules.patch
patch -Np1 -i "${srcdir}"/patches/brightray-use-system-ffmpeg.patch
patch -Np1 -i "${srcdir}"/patches/brightray-no-whole-archive.patch
for m in libchromiumcontent gyp; do
    git submodule init vendor/${m}
done
git submodule update

# Add extra libraries for unbundling
sed -e "s/'-lexpat',/'-lexpat', '<\!@(pkg-config --libs-only-l libavcodec libavformat libavutil libevent flac harfbuzz-icu jsoncpp minizip libpng vpx libwebpdemux libxml-2.0 libxslt)', '-ljpeg', '-lre2', '-lsnappy', '-latomic',/" \
    -e 's/gtk+-2\.0/gtk+-3.0/' \
    -i brightray.gyp

cd "${srcdir}"/electron/vendor/brightray/vendor/gyp
# Remove a useless $ORIGIN/lib/ rpath from the electron binary
patch -Np1 -i "${srcdir}"/patches/gyp-no-rpath.patch

cd "${srcdir}"/electron/vendor/brightray/vendor/libchromiumcontent
git checkout 2047bb141c3c2562796820371e2267359b395803
git submodule update --init vendor/python-patch
patch -Np1 -i "${srcdir}"/patches/libchromiumcontent-sort-filenames.patch  # deterministic build
patch -Np1 -i "${srcdir}"/patches/libchromiumcontent-use-system-tools.patch
patch -Np1 -i "${srcdir}"/patches/libchromiumcontent-use-system-ffmpeg.patch
patch -Np1 -i "${srcdir}"/patches/libchromiumcontent-static-library-only.patch
rm patches/third_party/ffmpeg/ffmpeg.patch  # Use system ffmpeg
echo 'Download chromium src...'
wget -c https://github.com/zcbenz/chromium-source-tarball/releases/download/${_chromiumver}/chromium-${_chromiumver}.tar.xz
echo 'Extracting chromium source...'
tar -xvJf chromium-${_chromiumver}.tar.xz
mv chromium-${_chromiumver} src
if [ ! -e src/.version ]; then
  echo "${_chromiumver}" > src/.version
fi
cd src
patch -Np1 -i "${srcdir}"/patches/chromium-cups.patch  # fixes build with CUPS 2.2
patch -Np1 -i "${srcdir}"/patches/chromium-gtk3.patch
patch -Np1 -i "${srcdir}"/patches/chromium-unset-madv_free.patch  # fixes crash with kernels < 4.5
patch -Np1 -i "${srcdir}"/patches/chromium-use-system-ffmpeg.patch
patch -Np1 -i "${srcdir}"/patches/chromium-use-system-minizip.patch
patch -Np1 -i "${srcdir}"/patches/chromium-use-system-re2.patch
python build/linux/unbundle/replace_gyp_files.py "${_chromium_flags[@]/#/-D}"
