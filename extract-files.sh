#!/bin/bash
#set -x
MANUFACTURER=marvell
DEVICE=pxa1088dkb

if [ -z "${ANDROIDFS_DIR}" ]; then
	echo ANDROIDFS_DIR is not set, pulling files from device
	(cd ../../.. &&
	 source setup.sh &&
	 time make adb &&
	 HOST_OUT=$(get_build_var HOST_OUT_$(get_build_var HOST_BUILD_TYPE)) &&
	 ${HOST_OUT}/bin/adb devices -l | grep device:${DEVICE})
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "no device connected"
		exit -1
	fi
	ANDROIDFS_DIR=`pwd`/../../../backup-${DEVICE} &&
	mkdir -p ${ANDROIDFS_DIR} &&
	adb pull /system/ ${ANDROIDFS_DIR}/system &&
	adb shell 'cat /dev/block/boot > /sdcard/boot.part' &&
	adb pull /sdcard/boot.part ${ANDROIDFS_DIR}
fi

if [ -n "${ANDROIDFS_DIR}" ]; then
	if [ -f ${ANDROIDFS_DIR}/boot.part ]; then
		head -c 4096 ${ANDROIDFS_DIR}/boot.part > ${ANDROIDFS_DIR}/boot.timh &&
		dd if=${ANDROIDFS_DIR}/boot.part of=${ANDROIDFS_DIR}/boot.img bs=4096 skip=1 &&
		(cd ../../.. &&
		 source setup.sh &&
		 time make unbootimg &&
		 HOST_OUT=$(get_build_var HOST_OUT_$(get_build_var HOST_BUILD_TYPE)) &&
		 KERNEL_DIR=device/${MANUFACTURER}/${DEVICE}-kernel &&
		 cp ${ANDROIDFS_DIR}/boot.img ${KERNEL_DIR} &&
		 ${HOST_OUT}/bin/unbootimg ${KERNEL_DIR}/boot.img &&
		 mv ${KERNEL_DIR}/boot.img-kernel ${KERNEL_DIR}/kernel &&
		 rm -f ${KERNEL_DIR}/boot.img &&
		 rm -f ${KERNEL_DIR}/boot.img-mk &&
		 cp ${KERNEL_DIR}/boot.img-ramdisk.cpio.gz device/${MANUFACTURER}/${DEVICE}/ &&
		 rm -f ${KERNEL_DIR}/boot.img-ramdisk.cpio.gz)
		ret=$?
		if [ $ret -ne 0 ]; then
			echo "Extract kernel failed"
			exit -1
		fi
	else
		echo "ANDROIDFS_DIR/boot.part does not exist"
		exit -1
	fi
else
	echo "ANDROIDFS_DIR is not set"
	exit -1
fi

if [ -f boot.img-ramdisk.cpio.gz ]; then
	(mkdir -p root &&
	 cd root &&
	 gunzip -c ../boot.img-ramdisk.cpio.gz | cpio -i)
	ret=$?
	if [ $ret -ne 0 ]; then
		echo "Extract ramdisk failed"
		exit -1
	fi
fi

DEVICE_BLOBS_LIST=${DEVICE}-vendor-blobs.mk
(cat << EOF) > $DEVICE_BLOBS_LIST
PRODUCT_COPY_FILES += \\
EOF

# a special copy
cp ${ANDROIDFS_DIR}/boot.timh boot.timh &&
echo -e "\tdevice/$MANUFACTURER/$DEVICE/boot.timh:boot.timh \\" >> $DEVICE_BLOBS_LIST

# copy_local_files
# puts files in this directory on the list of blobs to install
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_local_files()
{
    for NAME in $1
    do
        echo Adding \"$NAME\"
        echo -e "\tdevice/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\" >> $DEVICE_BLOBS_LIST
    done
}

# copy_files
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_files()
{
	mkdir -p $3
	for NAME in $1
	do
		cp ${ANDROIDFS_DIR}/$2/${NAME} $3/${NAME} &&
		echo -e "\tdevice/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\" >> $DEVICE_BLOBS_LIST
	done
}

DEVICE_ROOTFILES="
	init.pxa1088.rc
	init.pxa1088.usb.rc
	init.pxa1088.tel.rc
	init.pxa1088.sensor.rc
	fstab.pxa1088
	ueventd.pxa1088.rc
	"
copy_local_files "$DEVICE_ROOTFILES" "root" "root"

# GFX files
GFX_MODULE="
	galcore.ko
	"
copy_files "$GFX_MODULE" "system/lib/modules" "system/lib/modules"

GFX_EGL_FILES="
	egl.cfg
	libEGL_MRVL.so
	libGLESv1_CM_MRVL.so
	libGLESv2_MRVL.so
	"
copy_files "$GFX_EGL_FILES" "system/lib/egl" "system/lib/egl"

GFX_LIBS="
	libGAL.so
	libgputex.so
	libGLESv2SC.so
	libgcu.so
	libmvmem.so
	libion.so
	"
copy_files "$GFX_LIBS" "system/lib" "system/lib"

GFX_HW_LIB="
	gralloc.mrvl.so
	"
copy_files "$GFX_HW_LIB" "system/lib/hw" "system/lib/hw"

GFX_ETC_FILE="
	gfx.cfg
	"
copy_files "$GFX_ETC_FILE" "system/etc" "system/etc"

# idc file
IDC_FILES="
	ft5306-ts.idc
	synaptics_dsx_i2c.idc
	elan-ts.idc
	"
copy_files "$IDC_FILES" "system/usr/idc" "system/usr/idc"

# kcm file
KCM_FILES="
	pxa27x-keypad.kcm
	"
copy_files "$KCM_FILES" "system/usr/keychars" "system/usr/keychars"

# kl file
KL_FILES="
	pxa27x-keypad.kl
	"
copy_files "$KL_FILES" "system/usr/keylayout" "system/usr/keylayout"

