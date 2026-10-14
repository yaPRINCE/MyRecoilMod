ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CounterFlameRecoil
CounterFlameRecoil_FILES = Tweak.xm
CounterFlameRecoil_FRAMEWORKS = UIKit Foundation
CounterFlameRecoil_LIBRARIES = substrate
CounterFlameRecoil_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
