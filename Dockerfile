# syntax=docker/dockerfile:1
# SPDX-License-Identifier: Apache-2.0
# With thanks to https://github.com/tristanls/qemu-alpine/blob/master/Dockerfile for multi-core parallel build trick
# With thanks to https://unix.stackexchange.com/a/6431 for the trick how to separate stdout/stderr files with `tee`
# NOTE: apparently, vvfat requires the qcow(1) driver as well. Otherwise on startup: "Failed to locate qcow driver"
FROM docker.io/alpine:3.19.0 AS build

ARG QEMU_VERSION=8.2.0
ARG UHDD_SHA256=3b1ce2441e17adcd6aa80065b4181e5485e4f93a0ba87391d004741e43deb9d3
ARG DEVLOAD_SHA256=dcc085e01f26ab97ac5ae052d485d3e323703922c64da691b90c9b1505bcfd76

RUN apk --no-cache add build-base python3 ninja pkgconfig glib-dev meson pixman-dev bash perl

WORKDIR /Downloads

ADD https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz /Downloads
RUN tar xJf /Downloads/qemu-${QEMU_VERSION}.tar.xz
WORKDIR /Downloads/qemu-${QEMU_VERSION}
RUN ./configure --target-list=i386-softmmu --without-default-features --enable-kvm --enable-tcg --enable-tools --enable-vvfat --enable-qcow1
RUN make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)
RUN make install
RUN apk --no-cache add pixman glib libgcc
RUN qemu-system-i386 --version
RUN apk --no-cache add mtools

WORKDIR /Downloads

ADD https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.3/official/FD13-FloppyEdition.zip /Downloads
RUN unzip /Downloads/FD13-FloppyEdition.zip 144m/x86BOOT.img
RUN mv 144m/x86BOOT.img /media/

ADD https://github.com/Baron-von-Riedesel/HimemX/releases/download/v3.36/HimemX.zip /Downloads
RUN unzip /Downloads/HimemX.zip HimemX2.exe

ADD --checksum=sha256:$UHDD_SHA256 https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/repositories/1.3/drivers/uhdd.zip /Downloads
RUN unzip uhdd.zip BIN/UHDD.SYS

ADD --checksum=sha256:$DEVLOAD_SHA256 https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/repositories/1.3/base/devload.zip /Downloads
RUN unzip devload.zip BIN/DEVLOAD.COM

RUN echo "@ECHO OFF" > /tmp/FDAUTO.BAT
RUN echo "DEVLOAD /H UHDD.SYS /S20 /H" >> /tmp/FDAUTO.BAT
RUN echo "C:" >> /tmp/FDAUTO.BAT
RUN echo "IF EXIST CICD_DOS.BAT ECHO CICD_DOS.BAT file found in mounted volume. Running it..." >> /tmp/FDAUTO.BAT
RUN echo "IF EXIST CICD_DOS.BAT CALL CICD_DOS.BAT" >> /tmp/FDAUTO.BAT
RUN echo "IF NOT EXIST C:\CICD_DOS.BAT ECHO Could not run CICD_DOS.BAT file, since it was not found in mounted volume." >> /tmp/FDAUTO.BAT
RUN echo "A:\FREEDOS\BIN\FDAPM PUREOFF" >> /tmp/FDAUTO.BAT
RUN unix2dos /tmp/FDAUTO.BAT
RUN mdel -i /media/x86BOOT.img ::FDAUTO.BAT
RUN mcopy -i /media/x86BOOT.img /tmp/FDAUTO.BAT ::FDAUTO.BAT
RUN mcopy -i /media/x86BOOT.img /Downloads/HimemX2.exe ::HimemX2.exe
RUN mcopy -i /media/x86BOOT.img /Downloads/BIN/UHDD.SYS ::UHDD.SYS
RUN mcopy -i /media/x86BOOT.img /Downloads/BIN/DEVLOAD.COM ::DEVLOAD.COM
RUN echo "FILES=40" >> /tmp/FDCONFIG.SYS
RUN echo "BUFFERS=20" >> /tmp/FDCONFIG.SYS
RUN echo "LASTDRIVE=Z" >> /tmp/FDCONFIG.SYS
RUN echo "DOS=HIGH" >> /tmp/FDCONFIG.SYS
RUN echo "DEVICE=\HimemX2.exe" >> /tmp/FDCONFIG.SYS
RUN echo "SHELL=\FREEDOS\BIN\COMMAND.COM \FREEDOS\BIN /E:2048 /P=\FDAUTO.BAT" >> /tmp/FDCONFIG.SYS
RUN unix2dos /tmp/FDCONFIG.SYS
RUN mdel -i /media/x86BOOT.img ::FDCONFIG.SYS
RUN mcopy -i /media/x86BOOT.img /tmp/FDCONFIG.SYS ::FDCONFIG.SYS

FROM docker.io/alpine:3.19.0 AS image
COPY --from=build /media /media
COPY --from=build /usr/local /usr/local
RUN apk --no-cache add glib
RUN qemu-system-i386 --version
COPY run_cicd_dos.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/run_cicd_dos.sh

ENTRYPOINT ["/usr/local/bin/run_cicd_dos.sh"]
