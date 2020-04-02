include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DetectScreenshotEvent

DetectScreenshotEvent_FILES = Tweak.x
DetectScreenshotEvent_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
