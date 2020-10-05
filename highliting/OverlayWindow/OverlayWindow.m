#import "OverlayWindow.h"

@implementation OverlayWindow

// We override this initializer so we can set the NSBorderlessWindowMask styleMask, and set a few other important settings
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:NSWindowStyleMaskBorderless backing:bufferingType defer:flag];
    
    if ( self ) {
        [self setOpaque:NO]; // Needed so we can see through it when we have clear stuff on top
        [self setHasShadow:YES];
        [self setLevel: NSNormalWindowLevel];
        [self setCollectionBehavior:NSWindowCollectionBehaviorStationary|NSWindowCollectionBehaviorCanJoinAllSpaces|NSWindowCollectionBehaviorFullScreenAuxiliary];
        
    }
    
    [self setFrame:contentRect display:YES];
    [self initialize];
    return self;
}

- (id)accessibilityHitTest:(NSPoint)point {
    return nil;
}

- (void)initialize
{
    self.backgroundColor = [NSColor clearColor];
    self.contentView.wantsLayer = YES;
    self.contentView.layer.backgroundColor = [[NSColor clearColor] CGColor];
    self.contentView.layer.borderWidth = 2;
    self.contentView.layer.borderColor = [[NSColor redColor] CGColor];
    self.contentView.layer.cornerRadius = 5;
}

// Windows created with NSBorderlessWindowMask normally can't be key, but we want ours to be
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end
