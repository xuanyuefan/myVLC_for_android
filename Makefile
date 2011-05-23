# Sources and objects
JAVA_SOURCES=vlc-android/src/org/videolan/vlc/android/*.java
JNI_SOURCES=vlc-android/jni/*.c vlc-android/jni/*.h
VLC_APK=vlc-android/bin/VLC-debug.apk
APK_MK=vlc-android/jni/Android.mk
LIBVLCJNI=vlc-android/libs/armeabi/libvlcjni.so
LIBVLCJNI_H=vlc-android/jni/libvlcjni.h


all: vlc.apk

$(APK_MK):
	@echo "=== Creating Android.mk ==="; \
	prefix=""; \
	vlc_contrib=""; \
	# Check environment variables
	@if [ -z "$$ANDROID_NDK" -o -z "$$ANDROID_SDK" -o -z "$$VLC_BUILD_DIR" ]; then \
	    echo "You must define ANDROID_NDK, ANDROID_SDK and VLC_BUILD_DIR"; \
	    exit 1; \
	 fi; \
	# Append ../ to relative paths
	@if [ `echo $(VLC_BUILD_DIR) | head -c 1` != "/" ] ; then \
	    prefix="../"; \
	 fi; \
	 if [ -z "$$VLC_CONTRIB" ] ; then \
	    VLC_CONTRIB="../../contrib/build"; \
	 fi; \
	 if [ `echo "$$VLC_CONTRIB" | head -c 1` != "/" ] ; then \
	    vlc_contrib="../$$VLC_CONTRIB"; \
     else \
	    vlc_contrib="$$VLC_CONTRIB"; \
	 fi; \
	 modules=`find $$VLC_BUILD_DIR/modules -name '*.a'|grep -v stats`; \
	 LDFLAGS=""; \
	 DEFINITION=""; \
	 BUILTINS="const void *vlc_builtins_modules[] = {\n"; \
	 for file in $$modules; do \
	     name=`echo $$file | sed 's/.*\.libs\/lib//' | sed 's/_plugin\.a//'`; \
	     LDFLAGS="$$LDFLAGS\t$$prefix$$file \\\\\n"; \
	     DEFINITION=$$DEFINITION"vlc_declare_plugin($$name);\n"; \
	     BUILTINS=$$BUILTINS"    vlc_plugin($$name),\n"; \
	 done; \
	 BUILTINS=$$BUILTINS"    NULL\n};\n"; \
	 rm -f $(LIBVLCJNI_H); \
	 printf "/* File: libvlcjni.h"                                             > $(LIBVLCJNI_H); \
	 printf " * Autogenerated from the list of modules"                       >> $(LIBVLCJNI_H); \
	 printf " */\n"                                                           >> $(LIBVLCJNI_H); \
	 printf "$$DEFINITION\n"                                                  >> $(LIBVLCJNI_H); \
	 printf "$$BUILTINS\n"                                                    >> $(LIBVLCJNI_H); \
	 rm -f $(APK_MK); \
	 printf 'LOCAL_PATH := $$(call my-dir)\n'                                  > $(APK_MK); \
	 printf "include \$$(CLEAR_VARS)\n"                                       >> $(APK_MK); \
	 printf "LOCAL_MODULE    := libvlcjni\n"                                  >> $(APK_MK); \
	 printf "LOCAL_SRC_FILES := libvlcjni.c aout.c thumbnailer.c\n"           >> $(APK_MK); \
	 printf "LOCAL_C_INCLUDES := \$$(LOCAL_PATH)/../../../../../include\n"    >> $(APK_MK); \
	 printf "LOCAL_LDLIBS := -L$$vlc_contrib/lib \\\\\n"                      >> $(APK_MK); \
	 printf "\t-L$$ANDROID_NDK/platforms/android-8/arch-arm/usr/lib \\\\\n"   >> $(APK_MK); \
	 printf "$$LDFLAGS"                                                       >> $(APK_MK); \
	 printf "\t$$prefix$$VLC_BUILD_DIR/compat/.libs/libcompat.a \\\\\n"       >> $(APK_MK); \
	 printf "\t$$prefix$$VLC_BUILD_DIR/src/.libs/libvlc.a \\\\\n"             >> $(APK_MK); \
	 printf "\t$$prefix$$VLC_BUILD_DIR/src/.libs/libvlccore.a \\\\\n"         >> $(APK_MK); \
	 printf "\t-ldl -lz -lm -logg -lOpenSLES -lvorbisenc -lvorbis -lFLAC -lspeex -ltheora -lavformat -lavcodec -lavcore -lavutil -lpostproc -lswscale -lmpeg2 -lgcc -lpng -ldca -ldvbpsi -ltwolame -lkate -llog -la52 -lliveMedia -lUsageEnvironment -lBasicUsageEnvironment -lgroupsock -lpixman-1\n" >> $(APK_MK); \
	 printf "include \$$(BUILD_SHARED_LIBRARY)\n"                             >> $(APK_MK)

$(LIBVLCJNI): $(JNI_SOURCES) $(APK_MK)
	@echo "=== Building libvlcjni ==="
	@cd vlc-android/; \
	 $(ANDROID_NDK)/ndk-build

vlc-android/local.properties:
	@echo "=== Preparing Ant ==="
	@if [ "$$ANDROID_SDK" = "" ] ; then echo "Error: ANDROID_SDK is not set" ; exit 1 ; \
	 else \
	 printf "# Auto-generated file. Do not edit.\nsdk.dir=$$ANDROID_SDK"       > vlc-android/local.properties ; fi

$(VLC_APK): $(LIBVLCJNI) $(JAVA_SOURCES) vlc-android/local.properties
	@echo "=== Building APK =="
	@if ! which ant >> /dev/null ; then \
	     echo "Error: Ant is not installed. Not compiling APK."; \
	     exit 1; \
	 fi; \
	 cd vlc-android && ant -q debug

libvlcjni: $(LIBVLCJNI)

vlc.apk: libvlcjni $(VLC_APK)

clean:
	rm -rf vlc-android/libs
	rm -rf vlc-android/obj
#	rm -rf vlc-android/bin

distclean: clean
	rm -f $(APK_MK)
	rm -f $(LIBVLCJNI_H)
	rm -f vlc-android/local.properties

install:
	@echo "=== Installing APK on a remote device ==="
	@echo "Waiting for a device to be ready..." && adb wait-for-device
	@echo "Installing package" && adb install -r $(VLC_APK)

run:
	@echo "=== Running application on device ==="
	@adb wait-for-device && adb shell monkey -p vlc.android -s 0 1

build-and-run: vlc.apk install run
	@echo "=== Application is running ==="
