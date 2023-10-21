LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE := OneNote

LOCAL_CERTIFICATE := testkey

LOCAL_SRC_FILES := onenote.apk

LOCAL_MODULE_CLASS := APPS

LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)

LOCAL_OPTIONAL_USES_LIBRARIES := com.sec.android.app.multiwindow org.apache.http.legacy android.test.base androidx.camera.extensions.impl androidx.window.extensions androidx.window.sidecar

include $(BUILD_PREBUILT)
