//
//  OSXAppHidhtlightDeledate.h
//  highliting
//
//  Created by Alaa Bzour on 9/1/20.
//  Copyright © 2020 Alaa Bzour. All rights reserved.
//
#import "OSXAppHidhtlightDeledate.h"
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN


#define OSX_APP_HIGHLIGHT_DELEGATE_H

@interface OSXAppHidhtlightDeledate : NSObject <NSApplicationDelegate> {
   
}

- (OSXAppHidhtlightDeledate*) initWithWindowId:(long) windowId;
- (void) hide;
- (void) show;
- (void) end;

@end

NS_ASSUME_NONNULL_END
