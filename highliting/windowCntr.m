//
//  windowCntr.m
//  highliting
//
//  Created by Alaa Bzour on 8/31/20.
//  Copyright © 2020 Alaa Bzour. All rights reserved.
//

#import "windowCntr.h"
#import "OSXAppHidhtlightDeledate.h"

@interface windowCntr () {
   
}

@end

@implementation windowCntr

- (void)windowDidLoad {
    [super windowDidLoad];

    // get Safari's window id by running on the terminal
    // osascript -e "tell application \"Safari\" to id of window 1"
    OSXAppHidhtlightDeledate *test = [[OSXAppHidhtlightDeledate alloc]initWithWindowId:359];
    [test show];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6000 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [test end];
    });
    
  
}

@end
