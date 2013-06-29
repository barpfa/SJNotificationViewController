/*
Copyright (c) <YEAR>, <OWNER>
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "SJNotificationViewController.h"
#import <QuartzCore/QuartzCore.h>

#define SLIDE_DURATION 0.25f
#define LABEL_RESIZE_DURATION 0.1f
#define COLOR_FADE_DURATION 0.25f

#define ERROR_HEX_COLOR 0xff0000
#define MESSAGE_HEX_COLOR 0x0f5297
#define SUCCESS_HEX_COLOR 0x00ff00
#define NOTIFICATION_VIEW_OPACITY 0.85f
#define IS_ARC              (__has_feature(objc_arc))

@implementation SJNotificationViewController

- (id)initWithParentView:(UIView*)pView
{
    self = [super init];
        
    if (self)
    {
        [self setParentView:pView];
		[self setNotificationLevel:SJNotificationLevelMessage];
        showSpinner = NO;
        
        UIView * theView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 44.0f)];
        _spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(288.0f, 22.0f, 30.0f, 30.0f)];
        [theView addSubview:_spinner];

        _label = [[UILabel alloc] initWithFrame:CGRectMake(12.0f, 11.0f, 288.0f, 21.0f)];
        [_label setBackgroundColor:[UIColor clearColor]];
        [_label setTextColor:[UIColor whiteColor]];
        [_label setMinimumFontSize:9];
        [_label setNumberOfLines:1];
        [_label setAdjustsFontSizeToFitWidth:YES];
        [_label setTextAlignment:NSTextAlignmentCenter];
        [theView addSubview:_label];

        self.view = theView;
        
        #if !IS_ARC
        [theView release];
        #endif
    }
    
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Showing/Hiding the Notification

- (void)show
{
    #if TESTING
    NSLog(@"showing notification view");
    #endif

	
    /* Override level's background color if background color is set manually */
    if (_backgroundColor) {
        [self.view setBackgroundColor:_backgroundColor];
    }
    
	/* Attach to the bottom of the parent view. */
	CGFloat yPosition;
    
    switch (_notificationPosition) {
        case SJNotificationPositionTop:
            yPosition = self.view.frame.size.height * -1;
            break;
            
        default:
            yPosition = [_parentView frame].size.height;

            break;
    }
	
	[self.view setFrame:CGRectMake(0, yPosition, self.view.frame.size.width, self.view.frame.size.height)];
	[_parentView addSubview:self.view];
	
	[UIView animateWithDuration:SLIDE_DURATION
					 animations:^{
						 /* Slide the notification view up. */
						 CGRect shownRect = CGRectMake(0,
													   [self yPositionWhenHidden:NO],
													   self.view.frame.size.width,
													   self.view.frame.size.height);
						 [self.view setFrame:shownRect];
					 }
	 ];
    
    if (_notificationDuration != SJNotificationDurationStay) {
        [self performSelector:@selector(hide) withObject:nil afterDelay:((CGFloat)_notificationDuration / 1000.0f)];
    }
}

- (void)hide
{
    #if TESTING
    NSLog(@"hiding notification view");
    #endif
	
	[UIView animateWithDuration:SLIDE_DURATION
					 animations:^{
						 /* Slide the notification view down. */
						 [self.view setFrame:CGRectMake(0, [self yPositionWhenHidden:YES], self.view.frame.size.width, self.view.frame.size.height)];
					 }
					 completion:^(BOOL finished) {
						 [self.view removeFromSuperview];
					 }
	];
}

#pragma mark - Calculating position
- (CGFloat)yPositionWhenHidden:(BOOL)hidden {
    CGFloat y;
    
    // when hidden
    if (hidden) {
        switch (_notificationPosition) {
            case SJNotificationPositionTop:
                y = self.view.frame.size.height * -1;
                break;
                
            case SJNotificationPositionBottom:
            default:
                y = [_parentView frame].size.height;
                break;
        }
    // when shown
    } else {
        switch (_notificationPosition) {
            case SJNotificationPositionTop:
                y = 0;
                break;
                
            case SJNotificationPositionBottom:
            default:
                y = [_parentView frame].size.height - self.view.frame.size.height;
                break;
        }
    }
    
    return y;
}

#pragma mark - Setting Notification Title

- (void)setNotificationTitle:(NSString *)t {
	notificationTitle = t;
	[_label setText:t];
}

#pragma mark - Setting Tap Action

- (void)setTapTarget:(id)target selector:(SEL)selector {
	for (UIGestureRecognizer *r in [self.view gestureRecognizers]) {
		[self.view removeGestureRecognizer:r];
	}
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:selector];
	[self.view addGestureRecognizer:tap];
    #if !IS_ARC
	[tap release];
    #endif
}

#pragma mark - Setting Notification Level

- (void)setNotificationLevel:(SJNotificationLevel)level {
	notificationLevel = level;
	
	UIColor *color;
    
    switch (notificationLevel) {
        case SJNotificationLevelError:
            color = [UIColor colorWithRed:((float)((ERROR_HEX_COLOR & 0xFF0000) >> 16))/255.0
                                    green:((float)((ERROR_HEX_COLOR & 0xFF00) >> 8))/255.0
                                     blue:((float)(ERROR_HEX_COLOR & 0xFF))/255.0 alpha:NOTIFICATION_VIEW_OPACITY];
            break;
        case SJNotificationLevelMessage:
            color = [UIColor colorWithRed:((float)((MESSAGE_HEX_COLOR & 0xFF0000) >> 16))/255.0
                                    green:((float)((MESSAGE_HEX_COLOR & 0xFF00) >> 8))/255.0
                                     blue:((float)(MESSAGE_HEX_COLOR & 0xFF))/255.0 alpha:NOTIFICATION_VIEW_OPACITY];
            break;
        case SJNotificationLevelSuccess:
            color = [UIColor colorWithRed:((float)((SUCCESS_HEX_COLOR & 0xFF0000) >> 16))/255.0
                                    green:((float)((SUCCESS_HEX_COLOR & 0xFF00) >> 8))/255.0
                                     blue:((float)(SUCCESS_HEX_COLOR & 0xFF))/255.0 alpha:NOTIFICATION_VIEW_OPACITY];
            break;
        default:
            break;
    }
	
	[UIView animateWithDuration:COLOR_FADE_DURATION
					 animations:^ {
						 [self.view setBackgroundColor:color];
					 }
	];
}

#pragma mark - Spinner

- (void)setShowSpinner:(BOOL)b
{
	showSpinner = b;
	if (showSpinner) {
        #if TESTING
        NSLog(@"spinner showing");
        #endif
		
		[_spinner.layer setOpacity:1.0];
		[UIView animateWithDuration:LABEL_RESIZE_DURATION
						 animations:^{
							 [_label setFrame:CGRectMake(44, _label.frame.origin.y, 258, _label.frame.size.height)];
						 }
						 completion:^(BOOL finished) {
							 [_spinner startAnimating];
						 }
		];
	} else {
        #if TESTING
        NSLog(@"spinner not showing");
        #endif
		
		
		[_spinner stopAnimating];
		[_spinner.layer setOpacity:0.0];
		[UIView animateWithDuration:LABEL_RESIZE_DURATION
						 animations:^{
							 [_label setFrame:CGRectMake(12, _label.frame.origin.y, 290, _label.frame.size.height)];
						 }
		 ];
	}
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	/* By default, tapping the notification view hides it. */
	[self setTapTarget:self selector:@selector(hide)];
    [self setShowSpinner:showSpinner];
	
	[_label setText:notificationTitle];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc
{
    #if !IS_ARC
    [_spinner release]; self.spinner = nil;
    [_label release]; self.label = nil;
    [super dealloc];
    #endif
}

@end
