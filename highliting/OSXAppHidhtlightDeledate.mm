//
//  OSXAppHidhtlightDeledate.m
//  highliting
//
//  Created by Alaa Bzour on 9/1/20.
//  Copyright © 2020 Alaa Bzour. All rights reserved.
//

#import "OSXAppHidhtlightDeledate.h"
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>
#import <CoreGraphics/CoreGraphics.h>
#include <Foundation/NSDistributedNotificationCenter.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <ApplicationServices/ApplicationServices.h>

static AXObserverRef axObserver;
static AXUIElementRef axApplication;

@implementation
OSXAppHidhtlightDeledate {
//    NSWindow *overlayWindow;
//    NSWindow *trackingWin;
    BOOL isHighlightSharing;
    long appWindowId;
    pid_t pid;
}

- (OSXAppHidhtlightDeledate*) initWithWindowId:(long) windowId {
    NSLog(@"IN AppHidhtlightDeledate : init");
    self = [super init];
    if(!self)
        return nil;

    NSLog(@"AppHidhtlightDeledate : initWithWindowId");

    isHighlightSharing = YES;
    
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL accessibilityEnabled = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);

    if(!accessibilityEnabled) {
        NSLog(@"AppHidhtlightDeledate : initWithWindowId : accessibility not enabled!");
    }
    appWindowId = windowId;
    NSLog(@"AppHidhtlightDeledate :Selected windows ID =%ld",windowId);

    NSNotificationCenter *center =  [[NSWorkspace sharedWorkspace] notificationCenter];
    [center addObserver:self selector:@selector(onDeactivate:) name:NSWorkspaceDidDeactivateApplicationNotification object:nil];

    [center addObserver:self
            selector:@selector(activeSpaceDidChange:)
            name:NSWorkspaceActiveSpaceDidChangeNotification
            object:[NSWorkspace sharedWorkspace]
    ];
    AXUIElementRef axUielementWindow;
    @try{
        pid = [self processIdWithWindowId :windowId];
        [self windowWithProcessId:pid window:&axUielementWindow];
        [self attachNotifications:pid];        
    }
    @catch(NSException *e){
        NSLog(@"AppHidhtlightDeledate :Unexpected execption %@",e);
    }
    return self;
}

- (NSColor *)addBorderToBackgroundForWindow:(NSWindow *)window
{
    NSImage *bg = [[NSImage alloc] initWithSize:[window frame].size];
    // Begin drawing into our main image
    [bg lockFocus];
    
    [[NSColor clearColor] set];
    NSRectFill(NSMakeRect(0, 0, [bg size].width, [bg size].height));
    
    [[NSColor redColor] set];
    
    NSRect bounds = NSMakeRect(0, 0, [window frame].size.width, [window frame].size.height);
    NSBezierPath *border = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:10 yRadius:10];
    [border setLineWidth:10];
    [border stroke];
    
    [bg unlockFocus];
    
    return [NSColor colorWithPatternImage:bg];
}

-(void) dealloc
{
    NSLog(@"IN AppHidhtlightDeledate : dealloc");
    if(self){
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self];
        NSDistributedNotificationCenter *distr_center = [NSDistributedNotificationCenter defaultCenter];
        [distr_center removeObserver:self];

    }
    
    NSLog(@"OUT AppHidhtlightDeledate : dealloc");
}



- (void)onDeactivate:(NSNotification*)event
{
    NSLog(@"IN AppHidhtlightDeledate : onDeactivate");
}

- (void)activeSpaceDidChange:(NSNotification *)notification {
    
    NSLog(@"OSXAppHidhtlightDeledate::activeSpaceDidChange");
}

-(void) show {
//    [self updateWindow:CFSTR("KWindowShow")];
}

-(void) hide {
//    [overlayWindow orderBack:NSApp];
//    [[NSApp mainWindow] makeKeyWindow];
//    overlayWindow = nil;
}

-(void) end {
    [self hide];
    [self detachNotifications];
}

- (CGRect) selectedAppCoordinates:(long) windowId {
    //m_mutex.lock();
    NSLog(@"selectedAppCoordinates - IN");
    CGRect rect;
    CGWindowID windowid[1];
    windowid[0]= windowId;
    CFArrayRef windowArray = CFArrayCreate ( nullptr, (const void **)windowid, 1 ,nullptr);
    CFArrayRef windowsdescription = CGWindowListCreateDescriptionFromArray(windowArray);
    CFDictionaryRef windowdescription = (CFDictionaryRef)CFArrayGetValueAtIndex ((CFArrayRef)windowsdescription, 0);
    if(CFDictionaryContainsKey(windowdescription, kCGWindowBounds))
    {
        CFDictionaryRef bounds = (CFDictionaryRef)CFDictionaryGetValue (windowdescription, kCGWindowBounds);
        if(bounds)
        {
            if(CGRectMakeWithDictionaryRepresentation(bounds, &rect)){
                //CGFloat screenHeight = [[[NSScreen screens] objectAtIndex:0] frame].size.height;
                //CGPoint origin= CGPointMake(rect.origin.x, screenHeight - rect.size.height - rect.origin.y);
//                appWinRect->setX(rect.origin.x);
//                appWinRect->setY(rect.origin.y);
//                appWinRect->setWidth(rect.size.width);
//                appWinRect->setHeight(rect.size.height);
                
                NSLog(@"x: %f, y: %f, width: %f, height: %f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
            }
        }
    }
    CFRelease(windowArray);
    NSLog(@"selectedAppCoordinates - OUT");
    //m_mutex.unlock();
    
    return rect;
}

- (void)updateWindow:(CFStringRef)notificationName {
    
    CGRect rect = [self selectedAppCoordinates:appWindowId]; // coords of Safari
    
    // JUMA, DO YOUR MAGIC HERE (create, update outline)
   
//    CFComparisonResult result;
//    result = CFStringCompareWithOptions(notificationName, kAXWindowMiniaturizedNotification, CFRangeMake(0,CFStringGetLength(kAXWindowMiniaturizedNotification)), kCFCompareCaseInsensitive);
//    if (result == kCFCompareEqualTo) {
//        [overlayWindow orderBack:NSApp];
//        [[NSApp mainWindow] makeKeyWindow];
//    } else{
//        NSRunningApplication* app = [NSRunningApplication
//                                     runningApplicationWithProcessIdentifier: pid];
//        [app activateWithOptions: NSApplicationActivateAllWindows];
//
//        // Get all the windows
//        CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
//        NSArray* arr = CFBridgingRelease(windowList);
//        // Loop through the windows
//        for (NSMutableDictionary* entry in arr)
//        {
//            // Get window PID
//            pid_t apid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
//            if (apid == pid) {
//
//
//                NSArray * windowsArray = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID));
//                CGRect m_rect = CGRectZero;
//                for (NSDictionary *dic in windowsArray) {
//                    if([[dic objectForKey:@"kCGWindowOwnerPID"]intValue] == pid) {
//
//                        m_rect = CGRectMake([[[dic objectForKey:@"kCGWindowBounds"]objectForKey:@"X"]intValue], [[[dic objectForKey:@"kCGWindowBounds"]objectForKey:@"Y"]intValue], [[[dic objectForKey:@"kCGWindowBounds"]objectForKey:@"Width"]intValue], [[[dic objectForKey:@"kCGWindowBounds"]objectForKey:@"Height"]intValue]);
//                        break;
//                    }
//                }
//
//                NSRect frame = NSMakeRect(m_rect.origin.x - 10, ([NSScreen mainScreen].frame.size.height -  m_rect.origin.y - m_rect.size.height) - 10, m_rect.size.width + 20, m_rect.size.height + 20);
//
//
//                if (overlayWindow) {
//                    NSLog(@"updateWindow - update overlayWindow");
//                    [overlayWindow setFrame: frame display: YES animate: NO];
//                    [overlayWindow setBackgroundColor:[self addBorderToBackgroundForWindow:overlayWindow]];
//                    [overlayWindow setViewsNeedDisplay:NO];
//
//                } else {
//                    NSLog(@"updateWindow - create overlayWindow");
//                    overlayWindow = [[NSWindow alloc]initWithContentRect:frame
//                                                               styleMask:NSWindowStyleMaskBorderless
//                                                                 backing:NSBackingStoreBuffered
//                                                                   defer:NO];
//                    overlayWindow.backgroundColor = [NSColor clearColor];
//
//                    [overlayWindow setBackgroundColor:[self addBorderToBackgroundForWindow:overlayWindow]];
//                    [overlayWindow makeKeyAndOrderFront:NSApp];
//                }
//            }
//        }
//    }
   
}


- (void)detachNotifications
{
    NSLog(@"IN AppHidhtlightDeledate : detachNotifications");
    if(axObserver == NULL) {
        if(axApplication != NULL) {
        CFRelease(axApplication);
        }
        axApplication = NULL;
        return;
    }
    AXObserverRemoveNotification(axObserver, axApplication, kAXApplicationActivatedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowDeminiaturizedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowMiniaturizedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowMovedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXWindowResizedNotification);
    AXObserverRemoveNotification(axObserver, axApplication, kAXFocusedWindowChangedNotification);
    CFRunLoopRemoveSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(axObserver), kCFRunLoopDefaultMode);
    CFRelease(axObserver);
    axObserver = NULL;
    CFRelease(axApplication);
    axApplication = NULL;
    NSLog(@"OUT AppHidhtlightDeledate : detachNotifications");
}


- (pid_t)processIdWithWindowId:(long)windowId;
{
    NSLog(@"IN AppHidhtlightDeledate : processIdWithWindowId %ld",windowId);
    CGWindowID windowid[1];
    windowid[0] = windowId;
    CFArrayRef windowIdArray = CFArrayCreate ( nullptr, (const void **)windowid, 1 ,nullptr);
    CFArrayRef arrWindowsdescription = CGWindowListCreateDescriptionFromArray(windowIdArray);
    CFDictionaryRef window = (CFDictionaryRef)CFArrayGetValueAtIndex ((CFArrayRef)arrWindowsdescription, 0);
    // Get pid of application owning the window
    CFNumberRef pid_ref = reinterpret_cast<CFNumberRef>(CFDictionaryGetValue(window, kCGWindowOwnerPID));
    int pid;
    CFNumberGetValue(pid_ref, kCFNumberIntType, &pid);
    CFRelease(windowIdArray);
    NSLog(@"IN AppHidhtlightDeledate : processIdWithWindowId pid=%d",pid);
    return (pid_t)pid;
}

- (void)windowWithProcessId:(pid_t)pid window:(AXUIElementRef *)window
{
    NSLog(@"IN AppHidhtlightDeledate : windowWithProcessId pid[%d]",pid);
    //if(axApplication==NULL){
        axApplication = AXUIElementCreateApplication(pid);
    //}
    CFBooleanRef boolRef;
    AXUIElementCopyAttributeValue(axApplication, kAXHiddenAttribute, (const void **)&boolRef);
    if(boolRef == NULL || CFBooleanGetValue(boolRef)) {
        NSLog(@"IN AppHidhtlightDeledate : application associated to windowWithProcessId pid[%d] is hide.",pid);
        *window = NULL;
    } else {
        AXError axError = AXUIElementCopyAttributeValue(axApplication, kAXFocusedWindowAttribute, (const void **)window);
        if (axError != kAXErrorSuccess) {
            NSLog(@"IN AppHidhtlightDeledate : windowWithProcessId error=%@",axError);
        }
    }
    NSLog(@"OUT AppHidhtlightDeledate : windowWithProcessId");
}

void updateCallback (AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    NSLog(@"AppHidhtlightDeledate : updateCallback :notificationName[%@]",notification);
    OSXAppHidhtlightDeledate *_rainbowHighlightDelegate = (__bridge OSXAppHidhtlightDeledate *)refcon;
    [_rainbowHighlightDelegate bringWindowToFront];
    [_rainbowHighlightDelegate updateWindow:notification];
}

- (void) bringWindowToFront {
//    [overlayWindow orderFront:NSApp];
}

- (void)attachNotifications:(pid_t)pid
{
    NSLog(@"IN AppHidhtlightDeledate : attachNotifications pid[%d]",pid);
    if(axApplication == NULL) {
        NSLog(@"IN AppHidhtlightDeledate : axApplication = NULL so return.");
        return;
    }
    AXObserverCreate(pid, updateCallback, &axObserver);
    
    if(axObserver!=NULL){
        
        AXObserverAddNotification(axObserver, axApplication, kAXApplicationActivatedNotification, (__bridge void *)(self));
        AXObserverAddNotification(axObserver, axApplication, kAXWindowDeminiaturizedNotification, (__bridge void *)(self));
        AXObserverAddNotification(axObserver, axApplication, kAXWindowMiniaturizedNotification, (__bridge void *)(self));
        AXObserverAddNotification(axObserver, axApplication, kAXWindowMovedNotification, (__bridge void *)(self));
        AXObserverAddNotification(axObserver, axApplication, kAXWindowResizedNotification, (__bridge void *)(self));
        AXObserverAddNotification(axObserver, axApplication, kAXFocusedWindowChangedNotification, (__bridge void *)(self));
        CFRunLoopAddSource([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(axObserver), kCFRunLoopDefaultMode);
    }
    NSLog(@"OUT AppHidhtlightDeledate : attachNotifications");
}



@end
