# SPDX-License-Identifier: Apache-2.0
# With thanks to https://github.com/tristanls/qemu-alpine/blob/master/Dockerfile for multi-core parallel build trick
# With thanks to https://unix.stackexchange.com/a/6431 for the trick how to separate stdout/stderr files with `tee`
# NOTE: apparently, vvfat requires the qcow(1) driver as well. Otherwise on startup: "Failed to locate qcow driver"
FROM alpine:3.15.1

ARG QEMU_VERSION=7.0.0-rc0

RUN apk update \
    && apk add --upgrade apk-tools \
    && apk upgrade \
    && apk add build-base wget python3 ninja pkgconfig glib-dev meson pixman-dev bash perl \
    && mkdir /Downloads \
    && cd /Downloads \
    && wget -qO- https://download.qemu.org/qemu-${QEMU_VERSION}.tar.xz | tar xvJf - \
    && wget -qO- \
           https://www.ibiblio.org/pub/micro/pc-stuff/freedos/files/distributions/1.3/official/FD13-FloppyEdition.zip \
           | unzip - 144m/x86BOOT.img \
    && mv 144m/x86BOOT.img /media/ \
    && rmdir 144m \
    && wget -qO- https://github.com/Baron-von-Riedesel/HimemX/releases/download/v3.36/HimemX.zip | unzip - HimemX2.exe \
    && cd qemu-${QEMU_VERSION} \
    && ./configure --target-list=i386-softmmu --without-default-features --enable-tcg --enable-tools --enable-vvfat --enable-qcow1 \
    && NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
    && make -j${NPROC} \
    && make install \
    && cd .. \
    && apk del perl bash pixman-dev meson glib-dev pkgconfig ninja python3 wget build-base \
    && apk add pixman glib libgcc \
    && qemu-system-i386 --version \
    && apk add mtools \
    && echo "@ECHO OFF" > /tmp/FDAUTO.BAT \
    && echo "C:" >> /tmp/FDAUTO.BAT \
    && echo "IF EXIST CICD_DOS.BAT ECHO CICD_DOS.BAT file found in mounted volume. Running it..." >> /tmp/FDAUTO.BAT \
    && echo "IF EXIST CICD_DOS.BAT CALL CICD_DOS.BAT" >> /tmp/FDAUTO.BAT \
    && echo "IF NOT EXIST CICD_DOS.BAT ECHO Could not run CICD_DOS.BAT file, since it was not found in mounted volume." >> /tmp/FDAUTO.BAT \
    && echo "A:\FREEDOS\BIN\FDAPM POWEROFF" >> /tmp/FDAUTO.BAT \
    && unix2dos /tmp/FDAUTO.BAT \
    && mdel -i /media/x86BOOT.img ::FDAUTO.BAT \
    && mcopy -i /media/x86BOOT.img /tmp/FDAUTO.BAT ::FDAUTO.BAT \
    && mcopy -i /media/x86BOOT.img /Downloads/HimemX2.exe ::HimemX2.exe \
    && echo "DOS=HIGH" >> /tmp/FDCONFIG.SYS \
    && echo "DEVICE=\HimemX2.exe" >> /tmp/FDCONFIG.SYS \
    && echo "SHELL=\FREEDOS\BIN\COMMAND.COM \FREEDOS\BIN /E:2048 /P=\FDAUTO.BAT" >> /tmp/FDCONFIG.SYS \
    && unix2dos /tmp/FDCONFIG.SYS \
    && mdel -i /media/x86BOOT.img ::FDCONFIG.SYS \
    && mcopy -i /media/x86BOOT.img /tmp/FDCONFIG.SYS ::FDCONFIG.SYS \
    && apk del mtools && rm -rf /Downloads && rm -rf /tmp/*

ENTRYPOINT (qemu-system-i386 \
-nographic \
-blockdev driver=file,node-name=fd0,filename=/media/x86BOOT.img -device floppy,drive=fd0 \
-drive if=virtio,format=raw,file=fat:rw:$(pwd) \
-boot order=a \
-audiodev wav,id=snd0,path=$(pwd)/ac97_out.wav -device AC97,audiodev=snd0 \
-audiodev wav,id=snd1,path=$(pwd)/adlib_out.wav -device adlib,audiodev=snd1 \
-audiodev wav,id=snd2,path=$(pwd)/sb16_out.wav -device sb16,audiodev=snd2 \
-audiodev wav,id=snd3,path=$(pwd)/pcspk_out.wav -machine pcspk-audiodev=snd3 \
| tee $(pwd)/qemu_stdout.log) 3>&1 1>&2 2>&3 | tee $(pwd)/qemu_stderr.log
