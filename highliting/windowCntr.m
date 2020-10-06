#import "windowCntr.h"
#import "OSXAppHidhtlightDeledate.h"

@interface windowCntr () {
    
}

@end

@implementation windowCntr

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // get Safari's window id using
    // osascript -e "tell application \"Safari\" to id of window 1"
    
    NSPipe* pipe = [NSPipe pipe];
    
    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/osascript"];
    [task setArguments:@[@"-e", @"tell application \"Safari\" to id of window 1"]];
    [task setStandardOutput:pipe];
    
    NSFileHandle* file = [pipe fileHandleForReading];
    [task launch];
    
    NSString *safariWindowId = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSLog (@"safariWindowId: %@", safariWindowId);
    
    // test highlighting Safari
    OSXAppHidhtlightDeledate *test = [[OSXAppHidhtlightDeledate alloc]initWithParams:NO windowOrScreenId:[safariWindowId doubleValue]];
    
    // test highlighting main screen
    NSDictionary *screenDescription = [[NSScreen mainScreen] deviceDescription];
    double screenId =[[screenDescription objectForKey:@"NSScreenNumber"] doubleValue];
//    OSXAppHidhtlightDeledate *test = [[OSXAppHidhtlightDeledate alloc]initWithParams:YES windowOrScreenId:screenId];
    
    [test show];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [test end];
    });
    
    
}

@end
