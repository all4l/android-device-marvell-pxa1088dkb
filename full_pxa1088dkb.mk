#
# Copyright 2013 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)
$(call inherit-product-if-exists, device/marvell/pxa1088dkb/pxa1088dkb-vendor-blobs.mk)
$(call inherit-product, device/marvell/pxa1088dkb/device.mk)

PRODUCT_NAME := full_pxa1088dkb
PRODUCT_DEVICE := pxa1088dkb
PRODUCT_BRAND := Android
PRODUCT_MODEL := pxa1088dkb
PRODUCT_MANUFACTURER := marvell

ADDITIONAL_BUILD_PROPERTIES += \
	persist.sys.display.format=2
