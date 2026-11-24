#import "SGUIMode.h"
#import "SGLog.h"
#import "SGPrefs.h"

// The redesign is Liquid Glass from iOS 26, where the system draws it. Below 26 the Kit draws a blur in its
// place (SGGlassEffect, SGRGlass), so the redesign is offered on every OS the mod runs on.
BOOL SGRedesignAvailable(void) {
    return YES;
}

// Below iOS 26 the redesign runs on a UIKit it was first written against only from 26 on (upstream issue #37 was
// an iOS 17 scene-update watchdog). If Spotify is killed in its first seconds three launches in a row, the
// redesign switches itself off, so a bad launch cannot lock the phone out of Mod Settings. The switch can be
// turned back on in Appearance.
static NSString *const kLaunchTries = @"spotifyglass.redesign.launchTries";
static const NSInteger kMaxLaunchTries = 3;
static const int64_t kSettleSeconds = 15;

static BOOL redesignHoldsThisLaunch(void) {
    if (@available(iOS 26.0, *)) return YES;
    NSInteger tries = SGInt(kLaunchTries, 0);
    if (tries >= kMaxLaunchTries) {
        SGSetEnabled(SGKeyRedesign, NO);
        SGSetInt(kLaunchTries, 0);
        SGLog(@"ui: the redesign was switched off, Spotify died in %ld launches in a row", (long)tries);
        return NO;
    }
    SGSetInt(kLaunchTries, tries + 1);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kSettleSeconds * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        SGSetInt(kLaunchTries, 0);
    });
    return YES;
}

BOOL SGRedesignedUI(void) {
    static BOOL on;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        on = SGRedesignedUIStored() && redesignHoldsThisLaunch();
        SGLog(@"ui: %@", on ? @"redesigned" : @"native");
    });
    return on;
}

BOOL SGNativeUI(void) {
    return !SGRedesignedUI();
}

BOOL SGRedesignedUIStored(void) {
    return SGRedesignAvailable() && SGFlag(SGKeyRedesign, YES);
}
