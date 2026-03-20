# CorunaTweaks
Some tweaks for Coruna exploit chain (iOS 13.0 - 17.2.1).



## Build

1. FloatLockScreen
`xcrun --sdk iphoneos clang -target arm64e-apple-ios14.0 -fobjc-arc -dynamiclib \
    -o LockFloatingBall.dylib LockFloatingBall.m \
    -framework Foundation -framework UIKit -framework QuartzCore -lobjc \
    -Wl,-dead_strip -Os -undefined dynamic_lookup && \
codesign -s - LockFloatingBall.dylib`



## Reference

1. [coruna](https://github.com/khanhduytran0/coruna)
2. [TweaksLoader](https://github.com/AldazActivator/TweaksLoader)

