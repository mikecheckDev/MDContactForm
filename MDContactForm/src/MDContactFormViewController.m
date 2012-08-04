//
//  MDContactFormViewController.m
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

//Adjust this value to expand or squish all items vertically (For example, if you want everything to fit on a single page!)
#define kVerticalSpacing 12.0f

//Alignment constants
#define kLeftLabelInset 10.0f
#define kRightLabelInset 10.0f
//Very large, but size to fit will size it properly for us
#define kVeryLargeLabelHeight 500.0

#define kLeftFieldInset 10.0f
#define kRightFieldInset 10.0f
#define kTextFieldHeight 31.0f

#define kTextViewDefaultFontSize 14.0

#define kSubmitButtonWidth 200.0
#define kSubmitButtonHeight 40.0

//Filename WITHOUT .plist extension
#define kMDContactFormFileName @"MDContactForm"

//plist keys (These shouldn't need to be changed, set-up your form in the plist file)
#define kMDFormTitleKey @"MDContactForm_Title"
#define kMDFormMessageKey @"MDContactForm_Message"

//form items
//Array of form items
#define kMDFormItemsKey @"MDContactForm_Items"
//form item type
#define kMDFormInputTypeKey @"MDContactForm_InputType"
//This is the POST input name
#define kMDFormInputIdKey @"MDContactForm_InputIdentifier"
//Only for kMDContactFormTextField
#define kMDFormInputPlaceholderTextKey @"MDContactForm_InputTextPlaceholder"
#define kMDFormInputValueKey @"MDContactForm_InputValue"
#define kMDFormInputHeightKey @"MDContactForm_InputHeight"
#define kMDFormInputFontSizeKey @"MDContactForm_InputFontSize"
#define kMDFormInputDisplayNameKey @"MDContactForm_InputDisplayName"
#define kMDFormInputIsRequiredKey @"MDContactForm_InputRequired"

//Submit
#define kMDFormSubmitTitleKey @"MDContactForm_SubmitTitle"
#define kMDFormSubmitURLKey @"MDContactForm_SubmitURL"
#define kMDFormSubmitSuccessMessageKey @"MDContactForm_SubmitSuccessMessage"
#define kMDFormSubmitFailedKey @"MDContactForm_SubmitFailed"

//input types
typedef enum _MDFormInputTypes {
    kMDContactFormTextField = 0,
    kMDContactFormTextView = 1,
    kMDContactFormHidden = 2
    } MDFormInputTypes;

#import "MDTextField.h"
#import "MDTextView.h"
#import "MDContactFormViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MDContactFormViewController ()

@end

@implementation MDContactFormViewController
@synthesize contentView;
@synthesize scrollView;

- (void)submitForm:(id)sender {

    NSMutableArray *missingFields = [[NSMutableArray alloc] init];

    for (UIView *view in self.contentView.subviews) {

        if ([view isKindOfClass:[MDTextView class]]) {

            MDTextView *textView = (MDTextView *)view;
            if (textView.isRequired && (textView.text == nil || textView.text.length == 0)) {
                [missingFields addObject:textView];
            }
        } else if ([view isKindOfClass:[MDTextField class]]) {

            MDTextField *textField = (MDTextField *)view;
            if (textField.isRequired && (textField.text == nil || textField.text.length == 0)) {
                [missingFields addObject:textField];
            }
        }
    }
    
    if ([missingFields count] == 0) {

        [self sendFormRequest];
    } else {
        
        UIColor *missingBackgroundColor = [UIColor redColor];
        for (UIView *view in missingFields) {

            view.layer.borderWidth = 2.0f;
            view.layer.borderColor = missingBackgroundColor.CGColor;
        }

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Required Field" message:@"Please fill in all required fields. (They have been outlined in red.)" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)sendFormRequest {

    NSDictionary *plistData = [self plistData];

    id submitURL = [plistData objectForKey:kMDFormSubmitURLKey];
    if ([self isString:submitURL]) {

        //build request string
        NSMutableString *requestString = [[NSMutableString alloc] init];
        for (UIView *view in self.contentView.subviews) {
            
            if ([view isKindOfClass:[MDTextView class]]) {
                
                MDTextView *textView = (MDTextView *)view;
                [requestString appendFormat:@"&%@=%@",textView.postName,[self encodedString:textView.text]];
            } else if ([view isKindOfClass:[MDTextField class]]) {
                
                MDTextField *textField = (MDTextField *)view;
                [requestString appendFormat:@"&%@=%@",textField.postName,[self encodedString:textField.text]];
            }
        }
        
        //append any non-visible fields
        //inputs
        id inputItems = [plistData objectForKey:kMDFormItemsKey];
        if ([self isArray:inputItems]) {
            
            for (NSInteger i = 0; i < [inputItems count]; i++) {
                
                id itemDictionary = [inputItems objectAtIndex:i];
                if ([self isDictionary:itemDictionary]) {
                    
                    MDFormInputTypes inputType = [[itemDictionary objectForKey:kMDFormInputTypeKey] integerValue];
                    switch (inputType) {
                        case kMDContactFormHidden: {
                         
                            id postName = [itemDictionary objectForKey:kMDFormInputIdKey];
                            id postValue = [itemDictionary objectForKey:kMDFormInputValueKey];
                            if ([self isString:postName] && postValue != nil) {
                                [requestString appendFormat:@"&%@=%@",postName,[self encodedString:postValue]];
                            }
                            break;
                        }
                        default:
                            break;
                    }
                }
            }
        }
        
        NSData *postData = [NSData dataWithBytes:[requestString UTF8String] length:[requestString length]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:submitURL]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
        [request setHTTPBody:postData];

        __weak id weakSelf = self;
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            int responseStatusCode = [httpResponse statusCode];
            if (error == nil && responseStatusCode == 200) {
                [weakSelf submitSucceeded];
            } else {
                [weakSelf submitFailed:error];
            }
        }];
        
    } else {
        NSLog(@"MDContactForm Error! - Missing or invalid URL");
    }
}

- (void)submitSucceeded {

    [self bgTap:nil];
    
    //clear fields
    for (UIView *view in self.contentView.subviews) {
        
        if ([view isKindOfClass:[MDTextView class]]) {
            
            MDTextView *textView = (MDTextView *)view;
            textView.text = @"";
        } else if ([view isKindOfClass:[MDTextField class]]) {
            
            MDTextField *textField = (MDTextField *)view;
            textField.text = @"";
        }
    }
    
    NSDictionary *plistData = [self plistData];
    id successMsg = [plistData objectForKey:kMDFormSubmitSuccessMessageKey];
    if ([self isString:successMsg]) {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:successMsg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Thank you. The form has been submitted!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)submitFailed:(NSError *)error {

    NSString *errorDesc = @"";
    if (error != nil && error.description != nil) {
        errorDesc = [NSString stringWithFormat:@" (%@)",error.description];
    }

    NSDictionary *plistData = [self plistData];
    id errorMsg = [plistData objectForKey:kMDFormSubmitFailedKey];
    if ([self isString:errorMsg]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@%@", errorMsg, errorDesc] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    } else {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Sorry an error occurred. Please try again later. %@", errorDesc] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (NSString *)encodedString:(NSString *)string {

    if (string == nil) {
        return @"";
    }

    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,(__bridge CFStringRef)string, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
}

- (void)viewDidLoad {

    [super viewDidLoad];
    
    NSDictionary *plistData = [self plistData];
    
    [self buildView:plistData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification {
 
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedKeyboardFrame = [self.scrollView.window convertRect:keyboardFrame toView:self.scrollView];
    CGRect intersection = CGRectIntersection(self.scrollView.frame, convertedKeyboardFrame);

    CGRect scrollViewFrame = self.scrollView.frame;
    scrollViewFrame.size.height -= intersection.size.height;
    [UIView animateWithDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                              self.scrollView.frame = scrollViewFrame;
                          }
                     completion:^(BOOL finished) {
                              
                          }];
}

- (void)keyboardWillHide:(NSNotification *)notification {

    NSDictionary *userInfo = [notification userInfo];

    CGRect scrollViewFrame = self.scrollView.frame;
    scrollViewFrame.size.height = self.scrollView.superview.frame.size.height;
    [UIView animateWithDuration:[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                            self.scrollView.frame = scrollViewFrame;
                        }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)buildView:(NSDictionary *)viewDictionary {

    //clean contentView
    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }
    CGRect contentFrame = self.contentView.frame;
    contentFrame.size.height = 0.0;
    [self.contentView setFrame:contentFrame];

    //title
    id title = [viewDictionary objectForKey:kMDFormTitleKey];
    if ([self isString:title]) {
        self.navigationItem.title = title;
        self.title = title;
    }

    //message
    id message = [viewDictionary objectForKey:kMDFormMessageKey];
    if ([self isString:message]) {
        [self addLabel:message alignment:UITextAlignmentCenter];
    }
    
    //inputs
    id inputItems = [viewDictionary objectForKey:kMDFormItemsKey];
    if ([self isArray:inputItems]) {
     
        for (NSInteger i = 0; i < [inputItems count]; i++) {
            
            id itemDictionary = [inputItems objectAtIndex:i];
            if ([self isDictionary:itemDictionary]) {
                
                //display label if needed
                id displayName = [itemDictionary objectForKey:kMDFormInputDisplayNameKey];
                if ([self isString:displayName]) {
                    [self addLabel:displayName alignment:UITextAlignmentLeft];
                }

                //displayField
                MDFormInputTypes inputType = [[itemDictionary objectForKey:kMDFormInputTypeKey] integerValue];
                switch (inputType) {
                    case kMDContactFormTextField:
                        [self addTextField:itemDictionary];
                        break;
                    case kMDContactFormTextView:
                        [self addTextView:itemDictionary];
                        break;
                    default:
                        break;
                }
            }
        }
    }
    
    //submit button
    CGRect submitButtonFrame = CGRectMake((self.contentView.frame.size.width - kSubmitButtonWidth) / 2.0f, self.contentView.frame.size.height + kVerticalSpacing, kSubmitButtonWidth, kSubmitButtonHeight);
    UIButton *submit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [submit setFrame:submitButtonFrame];
    [submit setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [submit setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [submit addTarget:self action:@selector(submitForm:) forControlEvents:UIControlEventTouchUpInside];

    //submit button title
    id submitTitle = [viewDictionary objectForKey:kMDFormSubmitTitleKey];
    if ([self isString:submitTitle]) {
        [submit setTitle:submitTitle forState:UIControlStateNormal];
    } else {
        [submit setTitle:@"Submit" forState:UIControlStateNormal];
    }
    [self addView:submit];

    //bottom border
    contentFrame = self.contentView.frame;
    contentFrame.size.height += 2.0f * kVerticalSpacing;
    self.contentView.frame = contentFrame;
    self.scrollView.contentSize = self.contentView.bounds.size;

    //backgroundTap
    UIButton *bgTap = [UIButton buttonWithType:UIButtonTypeCustom];
    bgTap.frame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
    [bgTap addTarget:self action:@selector(bgTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView insertSubview:bgTap atIndex:0];
}

- (void)bgTap:(id)sender {

    for (UIView *view in self.contentView.subviews) {
        if ([view respondsToSelector:@selector(resignFirstResponder)]) {
            [view resignFirstResponder];
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSDictionary *)plistData {

    NSString *plistPath = [[NSBundle mainBundle] pathForResource:kMDContactFormFileName ofType:@"plist"];
    return [[NSDictionary alloc] initWithContentsOfFile:plistPath];
}

#pragma mark - Helpers

- (void)addLabel:(NSString *)text alignment:(UITextAlignment)textAlignment {

    CGRect labelFrame = CGRectMake(kLeftLabelInset, self.contentView.frame.size.height + kVerticalSpacing, self.contentView.frame.size.width - kLeftLabelInset - kRightLabelInset, kVeryLargeLabelHeight);
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:textAlignment];
    [label setText:text];
    [label setNumberOfLines:0];
    [label sizeToFit];
    [label setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self addView:label];
}

- (void)addTextField:(NSDictionary *)dictionary {

    CGRect textFieldFrame = CGRectMake(kLeftFieldInset, self.contentView.frame.size.height + kVerticalSpacing, self.contentView.frame.size.width - kLeftFieldInset - kRightFieldInset, kTextFieldHeight);
    MDTextField *textField = [[MDTextField alloc] initWithFrame:textFieldFrame];
    [textField setBorderStyle:UITextBorderStyleRoundedRect];
    [textField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [textField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    textField.layer.cornerRadius = 8.0f;

    //post name
    id postName = [dictionary objectForKey:kMDFormInputIdKey];
    if ([self isString:postName]) {
        textField.postName = postName;
    }
    
    //required
    id isRequired = [dictionary objectForKey:kMDFormInputIsRequiredKey];
    if ([self isNumber:isRequired]) {
        textField.required = [isRequired boolValue];
    }

    //placeholder
    id placeholderString = [dictionary objectForKey:kMDFormInputPlaceholderTextKey];
    if ([self isString:placeholderString]) {
        textField.placeholder = placeholderString;
    }
    
    //value
    id valueString = [dictionary objectForKey:kMDFormInputValueKey];
    if ([self isString:valueString]) {
        textField.text = valueString;
    }
    
    //font size
    id fieldFontSize = [dictionary objectForKey:kMDFormInputFontSizeKey];
    if ([self isNumber:fieldFontSize]) {
        [textField setFont:[UIFont systemFontOfSize:[fieldFontSize floatValue]]];
    }

    [self addView:textField];
}

- (void)addTextView:(NSDictionary *)dictionary {
    
    CGRect textViewFrame = CGRectMake(kLeftFieldInset, self.contentView.frame.size.height + kVerticalSpacing, self.contentView.frame.size.width - kLeftFieldInset - kRightFieldInset, kTextFieldHeight);
    MDTextView *textView = [[MDTextView alloc] initWithFrame:textViewFrame];
    [textView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    textView.layer.cornerRadius = 5.0f;
    textView.contentInset = UIEdgeInsetsMake(5.0f, 5.0f, 5.0f, 5.0f);

    //post name
    id postName = [dictionary objectForKey:kMDFormInputIdKey];
    if ([self isString:postName]) {
        textView.postName = postName;
    }

    //required
    id isRequired = [dictionary objectForKey:kMDFormInputIsRequiredKey];
    if ([self isNumber:isRequired]) {
        textView.required = [isRequired boolValue];
    }

    //height
    id viewHeight = [dictionary objectForKey:kMDFormInputHeightKey];
    if ([self isNumber:viewHeight]) {
        textViewFrame.size.height = [viewHeight floatValue];
        textView.frame = textViewFrame;
    }

    //font size
    id viewFontSize = [dictionary objectForKey:kMDFormInputFontSizeKey];
    if ([self isNumber:viewFontSize]) {
        [textView setFont:[UIFont systemFontOfSize:[viewFontSize floatValue]]];
    } else {
        [textView setFont:[UIFont systemFontOfSize:kTextViewDefaultFontSize]];
    }
    
    //value
    id valueString = [dictionary objectForKey:kMDFormInputValueKey];
    if ([self isString:valueString]) {
        textView.text = valueString;
    }
    
    [self addView:textView];
}

- (void)addView:(UIView *)aView {

    CGRect contentFrame = self.contentView.frame;
    contentFrame.size.height = aView.frame.origin.y + aView.frame.size.height;
    self.contentView.frame = contentFrame;
    [self.contentView addSubview:aView];
    self.scrollView.contentSize = self.contentView.bounds.size;
}

- (BOOL)isString:(id)val {

    return (val != nil && [val isKindOfClass:[NSString class]]);
}

- (BOOL)isArray:(id)val {
    return (val != nil && [val isKindOfClass:[NSArray class]]);
}

- (BOOL)isDictionary:(id)val {
    return (val != nil && [val isKindOfClass:[NSDictionary class]]);
}

- (BOOL)isNumber:(id)val {
    return (val != nil && [val isKindOfClass:[NSNumber class]]);
}

@end
