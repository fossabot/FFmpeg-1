#
# From https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
#
# https://hub.docker.com/r/etherlabsio/ffmpeg/
#
#
FROM        ubuntu:16.04 AS base

WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 pulseaudio libass5 libfreetype6 libsdl2-2.0-0 libva1 libvdpau1 libxcb1 libxcb-shm0 libxcb-xfixes0 zlib1g libx264-148 libxv1 libva-drm1 libva-x11-1 libxcb-shape0 && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM base as build

ARG        PKG_CONFIG_PATH=/opt/ffmpeg/lib/pkgconfig
ARG        LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG        PREFIX=/opt/ffmpeg
ARG        MAKEFLAGS="-j2"

ENV         FFMPEG_VERSION=4.0.2     \
            X264_VERSION=20170226-2245-stable \
            SRC=/usr/local

RUN      buildDeps="autoconf \
                    automake \
                    cmake \
                    curl \
                    bzip2 \
                    libexpat1-dev \
                    g++ \
                    gcc \
                    git \
                    gperf \
                    libtool \
                    make \
                    nasm \
                    perl \
                    pkg-config \
                    python \
                    libssl-dev \
                    yasm \
                    libpulse-dev \
                    libxcb1-dev libxcb-shm0-dev   libxcb-xfixes0-dev \
                    libx264-dev \
                    zlib1g-dev" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}

## ffmpeg from etherlabsio/ffmpeg
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        curl -sLO https://github.com/etherlabsio/FFmpeg/archive/n${FFMPEG_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f n${FFMPEG_VERSION}.tar.gz 


RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        ./configure \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --disable-avresample \
        --disable-libopencore-amrnb \
        --disable-libopencore-amrwb \
        --disable-libass \
        --disable-libfreetype \
        --disable-libvidstab \
        --disable-libmp3lame \
        --disable-libopenjpeg \
        --disable-libopus \
        --disable-libtheora \
        --disable-libvorbis \
        --disable-libvpx \
        --disable-libx265 \
        --disable-libxvid \
        --disable-nonfree \
        --disable-openssl \
        --disable-libfdk_aac \
        --disable-libkvazaar \
        --disable-libaom \
        --disable-version3 \
        --enable-shared \
        --enable-gpl \
        --enable-libxcb \
        --enable-libx264 \
        --enable-postproc \
        --enable-small \
        --enable-libpulse \
        --extra-libs=-lpthread \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" && \
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin

## cleanup
RUN \
        ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
        cp ${PREFIX}/bin/* /usr/local/bin/ && \
        cp -r ${PREFIX}/share/ffmpeg /usr/local/share/ && \
        LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf

FROM        base AS release

ENV         LD_LIBRARY_PATH=/usr/local/lib

COPY --from=build /usr/local /usr/local/

# Let's make sure the app built correctly
