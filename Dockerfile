# SPDX-License-Identifier: Apache-2.0
# With thanks to https://github.com/tristanls/qemu-alpine/blob/master/Dockerfile for multi-core parallel build trick
# NOTE: apparently, vvfat requires the qcow(1) driver as well. Otherwise on startup: "Failed to locate qcow driver"
FROM alpine:3.15.0
ENV MOUNT_PATH /mnt/drive_d
WORKDIR /tmp
RUN apk update \
    && apk add --upgrade apk-tools \
    && apk upgrade \
    && apk add build-base wget python3 ninja pkgconfig glib-dev meson pixman-dev bash perl \
    && wget -qO- https://download.qemu.org/qemu-6.2.0.tar.xz | tar xvJf - \
    && wget -qO- \
           https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.3/previews/1.3-rc5/FD13-FloppyEdition.zip \
           | unzip - 144m/x86BOOT.img \
    && mv 144m/x86BOOT.img / \
    && rmdir 144m \
    && cd qemu-6.2.0 \
    && ./configure --target-list=i386-softmmu --without-default-features --enable-tcg --enable-tools --enable-vvfat --enable-qcow1 \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make -j${NPROC} \
    && make install \
    && cd .. \
    && apk del perl bash pixman-dev meson glib-dev pkgconfig ninja python3 wget build-base \
    && apk add pixman glib libgcc \
    && rm -rf /tmp/* \
    && qemu-system-i386 --version \
    && mkdir -p $MOUNT_PATH

RUN apk add mtools \
    && ls /usr/bin/mdir \
    && ls /x86BOOT.img \
    && mdir -i /x86BOOT.img \
    && echo $'@ECHO OFF \n\
C:\n\
DIR\n\
IF EXIST CICD.BAT CICD.BAT\n\
IF NOT EXIST CICD.BAT echo Could not run CICD.BAT file, since it was not found in mounted volume.\n\
A:\FREEDOS\BIN\FDAPM POWEROFF' > /tmp/FDAUTO.BAT \
    && cat /tmp/FDAUTO.BAT

#RUN mdel -i /x86BOOT.img ::FDCONFIG.SYS
RUN mdel -i /x86BOOT.img ::FDAUTO.BAT
RUN mcopy -i /x86BOOT.img /tmp/FDAUTO.BAT ::FDAUTO.BAT
RUN apk del mtools

#RUN echo n | qemu-system-i386 -nographic -blockdev driver=file,node-name=f0,filename=144m/x86BOOT.img -device floppy,drive=f0
#RUN qemu-system-i386 -display curses -blockdev driver=file,node-name=f0,filename=/x86BOOT.img -device floppy,drive=f0
#ENTRYPOINT ["qemu-system-i386", "-display", "curses", "-blockdev", "driver=file,node-name=f0,filename=/x86BOOT.img", "-device", "floppy,drive=f0"]
#ENTRYPOINT ["qemu-system-i386", "-nographic", "-blockdev", "driver=file,node-name=f0,filename=/x86BOOT.img", "-device", "floppy,drive=f0"]
ENTRYPOINT qemu-system-i386 -nographic -blockdev driver=file,node-name=f0,filename=/x86BOOT.img -device floppy,drive=f0 -drive if=virtio,format=raw,file=fat:rw:$MOUNT_PATH -boot order=a
