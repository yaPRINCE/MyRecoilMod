ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyRecoilMenu
MyRecoilMenu_FILES = Tweak.xm
MyRecoilMenu_FRAMEWORKS = UIKit Foundation
MyRecoilMenu_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 CounterFlame || true"
