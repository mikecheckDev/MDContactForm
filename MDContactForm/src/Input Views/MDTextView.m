//
//  MDTextView.m
//  Part of MDContactForm
//
//  Created by Mike Dougherty on 8/3/2012.
//  Copyright (c) 2012 Mike Dougherty. All rights reserved.
//
//  Latest code available here:
//  https://github.com/mikecheckDev/MDContactForm
//
//  For questions/support contact me here:
//  mike@mikecheck.net or http://mikecheck.net

#import "MDTextView.h"

@implementation MDTextView
@synthesize postName;
@synthesize required;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.postName = nil;
        self.required = NO;
    }
    return self;
}

@end
