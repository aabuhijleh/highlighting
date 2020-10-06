#import "OSXAppHidhtlightDeledate.h"
#import "OverlayWindow/OverlayWindow.h"
#include <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreServices/CoreServices.h>
#include <Foundation/Foundation.h>
#include <Foundation/NSDistributedNotificationCenter.h>

static AXObserverRef axObserver;
static AXUIElementRef axApplication;

@implementation OSXAppHidhtlightDeledate {
  long trackedWindowId;
  pid_t trackedAppPid;
  OverlayWindow *trackingWin;
}

- (OSXAppHidhtlightDeledate *)initWithWindowId:(long)windowId {
  NSLog(@"IN AppHidhtlightDeledate : init");
  self = [super init];
  if (!self)
    return nil;

  NSLog(@"AppHidhtlightDeledate : initWithWindowId");

  NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt : @YES};
  BOOL accessibilityEnabled =
      AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);

  if (!accessibilityEnabled) {
    NSLog(@"AppHidhtlightDeledate : initWithWindowId : accessibility not "
          @"enabled!");
  }
  trackedWindowId = windowId;
  NSLog(@"AppHidhtlightDeledate : Selected windows ID =%ld", windowId);

  AXUIElementRef axUielementWindow;
  @try {
    trackedAppPid = [self processIdWithWindowId:windowId];
    [self windowWithProcessId:trackedAppPid window:&axUielementWindow];
    [self attachNotifications:trackedAppPid];
  } @catch (NSException *e) {
    NSLog(@"AppHidhtlightDeledate :Unexpected execption %@", e);
  }
  return self;
}

- (void)dealloc {
  NSLog(@"IN AppHidhtlightDeledate : dealloc");
  if (self) {
//    [super dealloc];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
    NSDistributedNotificationCenter *distr_center =
        [NSDistributedNotificationCenter defaultCenter];
    [distr_center removeObserver:self];
  }
  NSLog(@"OUT AppHidhtlightDeledate : dealloc");
}

- (void)activeSpaceDidChange:(NSNotification *)notification {
  @try {
    CGRect rect = [self selectedAppCoordinates:trackedWindowId];

    if ((rect.origin.x == 0) && (rect.origin.y == 0)) {
      NSLog(@"OSXAppHidhtlightDeledate::activeSpaceDidChange : FULL SCREEN !");
    }

    NSLog(@"OSXAppHidhtlightDeledate::activeSpaceDidChange : shared "
          @"application size x[%f],y[%f],w[%f],h[%f]",
          rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
  } @catch (NSException *e) {
    NSLog(@"ERROR :OSXAppHidhtlightDeledate::activeSpaceDidChange : %@", e);
  }
}

- (void)show {
  if (trackingWin) {
    [trackingWin orderFrontRegardless];
  } else {
    // [self updateWindow:kAXApplicationActivatedNotification];
  }
}

- (void)hide {
  if (trackingWin) {
    [trackingWin orderOut:nil];
  }
}

- (void)end {
  [self hide];
  trackingWin = nil;
  [self detachNotifications];
}

- (CGRect)selectedAppCoordinates:(long)windowId {
  CGRect rect;
  CGWindowID windowid[1];
  windowid[0] = windowId;
  CFArrayRef windowArray =
      CFArrayCreate(nullptr, (const void **)windowid, 1, nullptr);
  CFArrayRef windowsdescription =
      CGWindowListCreateDescriptionFromArray(windowArray);
  CFDictionaryRef windowdescription = (CFDictionaryRef)CFArrayGetValueAtIndex(
      (CFArrayRef)windowsdescription, 0);
  if (CFDictionaryContainsKey(windowdescription, kCGWindowBounds)) {
    CFDictionaryRef bounds = (CFDictionaryRef)CFDictionaryGetValue(
        windowdescription, kCGWindowBounds);
    if (bounds) {
      if (CGRectMakeWithDictionaryRepresentation(bounds, &rect)) {
      }
    }
  }
  CFRelease(windowArray);
  return rect;
}

- (void)updateWindow:(CFStringRef)notificationName {
  @try {

    NSLog(@"notificationName: %@", notificationName);

    bool closed =
        CFStringCompareWithOptions(
            notificationName, kAXUIElementDestroyedNotification,
            CFRangeMake(0,
                        CFStringGetLength(kAXUIElementDestroyedNotification)),
            kCFCompareCaseInsensitive) == kCFCompareEqualTo;

    bool hidden =
        CFStringCompareWithOptions(
            notificationName, kAXApplicationHiddenNotification,
            CFRangeMake(0, CFStringGetLength(kAXApplicationHiddenNotification)),
            kCFCompareCaseInsensitive) == kCFCompareEqualTo;

    bool minimized =
        CFStringCompareWithOptions(
            notificationName, kAXWindowMiniaturizedNotification,
            CFRangeMake(0,
                        CFStringGetLength(kAXWindowMiniaturizedNotification)),
            kCFCompareCaseInsensitive) == kCFCompareEqualTo;

    if (closed || hidden || minimized) {
      [self hide];
    } else {

      CGRect rect = [self selectedAppCoordinates:trackedWindowId];

      CGSize screenSize = [[NSScreen mainScreen] frame].size;

      // **** Add Margin **** //
      NSRect frameR =
          NSMakeRect(rect.origin.x - 3,
                     screenSize.height - rect.size.height - rect.origin.y - 3,
                     rect.size.width + 6, rect.size.height + 6);

      if (trackingWin) {
        NSLog(@"updateWindow - update underlayWnd");

        // **** Update Underlaying Window **** //
        NSLog(@"x: %f, y: %f, width: %f, height: %f", frameR.origin.x,
              frameR.origin.y, frameR.size.width, frameR.size.height);

        [trackingWin setFrame:frameR display:YES];

        NSLog(@"needs display");

      } else {
        NSLog(@"updateWindow - create underlayWnd");

        // **** Create Underlaying Window **** //
        trackingWin = [[OverlayWindow alloc]
            initWithContentRect:frameR
                      styleMask:NSWindowStyleMaskBorderless
                        backing:NSBackingStoreBuffered
                          defer:NO];
        [trackingWin setIgnoresMouseEvents:true];
        [trackingWin orderWindow:NSWindowBelow relativeTo:0];

        //        BOOL fullScreen = true;
        //              if (fullScreen) {
        //                  [underlayWnd setLevel:NSMainMenuWindowLevel];
        //                  CGRect screenRect = CGRectMake(0, 0,
        //                  screenSize.width, screenSize.height); [underlayWnd
        //                  setFrame:screenRect display:YES];
        //              }
      }

      [self show];
    }

  } @catch (NSException *e) {
    NSLog(@"ERROR : updateWindow : %@", e);
    [self hide];
  }
}

- (void)detachNotifications {
  NSLog(@"IN AppHidhtlightDeledate : detachNotifications");
  if (axObserver == NULL) {
    if (axApplication != NULL) {
      CFRelease(axApplication);
    }
    axApplication = NULL;
    return;
  }

  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXUIElementDestroyedNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXApplicationHiddenNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXApplicationActivatedNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXWindowDeminiaturizedNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXWindowMiniaturizedNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXWindowMovedNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXWindowResizedNotification);
  AXObserverRemoveNotification(axObserver, axApplication,
                               kAXFocusedWindowChangedNotification);
  CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop],
                        AXObserverGetRunLoopSource(axObserver),
                        kCFRunLoopDefaultMode);
  CFRelease(axObserver);
  axObserver = NULL;
  CFRelease(axApplication);
  axApplication = NULL;
  NSLog(@"OUT AppHidhtlightDeledate : detachNotifications");
}

- (pid_t)processIdWithWindowId:(long)windowId {
  NSLog(@"IN AppHidhtlightDeledate : processIdWithWindowId %ld", windowId);
  CGWindowID windowid[1];
  windowid[0] = windowId;
  CFArrayRef windowIdArray =
      CFArrayCreate(nullptr, (const void **)windowid, 1, nullptr);
  CFArrayRef arrWindowsdescription =
      CGWindowListCreateDescriptionFromArray(windowIdArray);
  CFDictionaryRef window = (CFDictionaryRef)CFArrayGetValueAtIndex(
      (CFArrayRef)arrWindowsdescription, 0);
  // Get pid of application owning the window
  CFNumberRef pid_ref = reinterpret_cast<CFNumberRef>(
      CFDictionaryGetValue(window, kCGWindowOwnerPID));
  int pid;
  CFNumberGetValue(pid_ref, kCFNumberIntType, &pid);
  CFRelease(windowIdArray);
  NSLog(@"IN AppHidhtlightDeledate : processIdWithWindowId pid=%d", pid);
  return (pid_t)pid;
}

- (void)windowWithProcessId:(pid_t)pid window:(AXUIElementRef *)window {
  NSLog(@"IN AppHidhtlightDeledate : windowWithProcessId pid[%d]", pid);
  // if(axApplication==NULL){
  axApplication = AXUIElementCreateApplication(pid);
  //}
  CFBooleanRef boolRef;
  AXUIElementCopyAttributeValue(axApplication, kAXHiddenAttribute,
                                (const void **)&boolRef);
  if (boolRef == NULL || CFBooleanGetValue(boolRef)) {
    NSLog(@"IN AppHidhtlightDeledate : application associated to "
          @"windowWithProcessId pid[%d] is hide.",
          pid);
    *window = NULL;
  } else {
    AXError axError = AXUIElementCopyAttributeValue(
        axApplication, kAXFocusedWindowAttribute, (const void **)window);
    if (axError != kAXErrorSuccess) {
      NSLog(@"IN AppHidhtlightDeledate : windowWithProcessId error=%d",
            (int)axError);
    }
  }
  NSLog(@"OUT AppHidhtlightDeledate : windowWithProcessId");
}

void updateCallback(AXObserverRef observer, AXUIElementRef element,
                    CFStringRef notification, void *refcon) {
  NSLog(@"AppHidhtlightDeledate : updateCallback :notificationName[%@]",
        notification);
  OSXAppHidhtlightDeledate *_rainbowHighlightDelegate =
      (__bridge OSXAppHidhtlightDeledate *)refcon;
  [_rainbowHighlightDelegate updateWindow:notification];
}

- (void)attachNotifications:(pid_t)pid {
  NSLog(@"IN AppHidhtlightDeledate : attachNotifications pid[%d]", pid);
  if (axApplication == NULL) {
    NSLog(@"IN AppHidhtlightDeledate : axApplication = NULL so return.");
    return;
  }
  AXObserverCreate(pid, updateCallback, &axObserver);

  if (axObserver != NULL) {

    AXObserverAddNotification(axObserver, axApplication,
                              kAXUIElementDestroyedNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXApplicationHiddenNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXApplicationActivatedNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXWindowDeminiaturizedNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXWindowMiniaturizedNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXWindowMovedNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXWindowResizedNotification,
                              (__bridge void *)(self));
    AXObserverAddNotification(axObserver, axApplication,
                              kAXFocusedWindowChangedNotification,
                              (__bridge void *)(self));
    CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop],
                       AXObserverGetRunLoopSource(axObserver),
                       kCFRunLoopDefaultMode);
  }
  NSLog(@"OUT AppHidhtlightDeledate : attachNotifications");
}

@end
