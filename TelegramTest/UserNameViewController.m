//
//  UserNameViewController.m
//  Telegram
//
//  Created by keepcoder on 15.10.14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "UserNameViewController.h"
#import "UserInfoShortTextEditView.h"
#import "TGTimer.h"
@interface UserNameViewController ()
@property (nonatomic,strong) TMTextButton *doneButton;
@end


@interface UserNameViewContainer : TMView<NSTextFieldDelegate>
@property (nonatomic,strong) UserInfoShortTextEditView *textView;
@property (nonatomic,strong) TMTextButton *button;
@property (nonatomic,strong) NSTextView *descriptionView;

@property (nonatomic,strong) UserNameViewController *controller;

@property (nonatomic,strong) NSProgressIndicator *progressView;
@property (nonatomic,strong) NSImageView *successView;
@property (nonatomic,strong) TGTimer *timer;
@property (nonatomic,assign) BOOL isSuccessChecked;
@property (nonatomic,assign) BOOL isRemoteChecked;
@property (nonatomic,strong) NSString *lastUserName;
@property (nonatomic,strong) NSString *checkedUserName;
@property (nonatomic,strong) RPCRequest *request;
@end


@implementation UserNameViewContainer

-(id)initWithFrame:(NSRect)frameRect {
    if(self = [super initWithFrame:frameRect]) {
        
        
        self.successView = imageViewWithImage(image_UsernameCheck());
        
        self.progressView = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 15, 15)];
        
        [self.progressView setStyle:NSProgressIndicatorSpinningStyle];
        
        
        self.textView = [[UserInfoShortTextEditView alloc] initWithFrame:NSMakeRect(100, 80, NSWidth(self.frame) - 200, 23)];
        
        [self.successView setFrameOrigin:NSMakePoint(NSWidth(self.textView.frame) - NSWidth(self.successView.frame), 8)];
        
        [self.progressView setFrameOrigin:NSMakePoint(NSWidth(self.textView.frame) - NSWidth(self.progressView.frame), 5)];
        
        self.successView.autoresizingMask = self.progressView.autoresizingMask = NSViewMinXMargin;
        
        [self.progressView setHidden:YES];
        
        [self.successView setHidden:YES];
        
        
        [self.textView addSubview:self.successView];
        
        [self.textView addSubview:self.progressView];
        
        
        
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        
        [str appendString:NSLocalizedString(@"UserName.placeHolder", nil) withColor:DARK_GRAY];
        [str setAlignment:NSLeftTextAlignment range:str.range];
        [str setFont:[NSFont fontWithName:@"HelveticaNeue" size:15] forRange:str.range];
        
        [[self.textView textView].cell setPlaceholderAttributedString:str];
        [[self.textView textView] setPlaceholderPoint:NSMakePoint(0, 0)];
        
        self.textView.textView.delegate = self;
        
        [self addSubview:self.textView];
        
        [self.textView.textView setAction:@selector(performEnter)];
        [self.textView.textView setTarget:self];
        [self.textView.textView setNextKeyView:self];
        [self.textView.textView setFrameOrigin:NSMakePoint(0, NSMinY(self.textView.textView.frame))];
        
        
        self.descriptionView = [[NSTextView alloc] initWithFrame:NSMakeRect(98, 110, NSWidth(self.frame) - 200, 100)];
        
        [self.descriptionView setString:NSLocalizedString(@"UserName.description", nil)];
        
        [self.descriptionView setFont:[NSFont fontWithName:@"HelveticaNeue" size:12]];
        
        [self.descriptionView sizeToFit];
        [self.descriptionView setSelectable:NO];
        
        [self.descriptionView setTextContainerInset:NSMakeSize(0, 0)];
        
        
        [self addSubview:self.descriptionView];
        
        self.button = [[TMTextButton alloc] initWithFrame:NSMakeRect(100, 110+NSHeight(self.descriptionView.frame)+10, 150, 20)];
        

    }
    
    return self;
}

- (void)performEnter {
    if(self.isRemoteChecked && ![[UsersManager currentUser].user_name isEqualToString:self.checkedUserName]) {
        [self.textView.textView resignFirstResponder];
        self.controller.doneButton.tapBlock();
    }
}

-(void)updateSaveButton {
    
    if([[UsersManager currentUser].user_name isEqualToString:self.textView.textView.stringValue]) {
        [self.controller.doneButton setDisable:YES];
        
        return;
    }
    
    [self.controller.doneButton setDisable:(self.textView.textView.stringValue.length < 5 && self.textView.textView.stringValue.length != 0) || (!self.isRemoteChecked)];
}

- (void)controlTextDidChange:(NSNotification *)obj {
    
    
    self.textView.textView.stringValue = [[self.textView.textView.stringValue componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];;
    
    
    [self updateSaveButton];
    
    
    if(self.textView.textView.stringValue.length >= 5 || self.textView.textView.stringValue.length == 0) {
         [self updateChecker];
    } else {
        [self.progressView setHidden:YES];
        [self.progressView stopAnimation:self];
        [self.successView setHidden:YES];
    }
   
}


-(void)updateChecker {
    
    if([self.textView.textView.stringValue isEqualToString:[UsersManager currentUser].user_name]) {
        [self.progressView setHidden:YES];
        [self.progressView stopAnimation:self];
        [self.successView setHidden:NO];
    } else if(![self.lastUserName isEqualToString:self.textView.textView.stringValue]) {
        
        if(!self.timer) {
            
            self.isSuccessChecked = NO;
            self.isRemoteChecked = [self.textView.textView.stringValue isEqualToString:[UsersManager currentUser].user_name];
            [self updateSaveButton];
            
            self.timer = [[TGTimer alloc] initWithTimeout:0.2 repeat:NO completion:^{
                
               
                
                [self.successView setHidden:YES];
                [self.progressView setHidden:NO];
                [self.progressView startAnimation:self];
                
                if(self.request)
                    [self.request cancelRequest];
                
                NSString *userNameToCheck = self.textView.textView.stringValue;
                
                self.request = [RPCRequest sendRequest:[TLAPI_account_checkUsername createWithUsername:userNameToCheck] successHandler:^(RPCRequest *request, id response) {
                    
                    self.isSuccessChecked = [response isKindOfClass:[TL_boolTrue class]];
                    self.isRemoteChecked = YES;
                    self.checkedUserName = userNameToCheck;
                    
                    [self updateSaveButton];
                    
                    [self.progressView setHidden:YES];
                    [self.progressView stopAnimation:self];
                    
                    [self.successView setHidden:!self.isSuccessChecked];
                    
                } errorHandler:^(RPCRequest *request, RpcError *error) {
                    
                    
                }];
                
                
            } queue:dispatch_get_current_queue()];
            
            [self.timer start];
            
        } else {
            [self.timer invalidate];
            self.timer = nil;
            [self updateChecker];
        }

        
    }
    
    self.lastUserName = self.textView.textView.stringValue;
    
}

-(void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    
    NSSize size = [self.descriptionView.attributedString sizeForTextFieldForWidth:newSize.width - 200];
    
   
    
    [self.descriptionView setFrameSize:size];
    
    [self.button setFrameOrigin:NSMakePoint(100, 110+NSHeight(self.descriptionView.frame))];
}

@end


@implementation UserNameViewController

-(void)loadView {
    
    self.view = [[UserNameViewContainer alloc] initWithFrame:self.frameInit];
    
    self.view.isFlipped = YES;
    
    TMTextField* centerTextField = [TMTextField defaultTextField];
    [centerTextField setAlignment:NSCenterTextAlignment];
    [centerTextField setFont:[NSFont fontWithName:@"HelveticaNeue" size:15]];
    [centerTextField setTextColor:NSColorFromRGB(0x222222)];
    [centerTextField setDrawsBackground:NO];
    
    [centerTextField setStringValue:NSLocalizedString(@"Profile.ChangeUserName", nil)];
    
    [centerTextField setFrameOrigin:NSMakePoint(centerTextField.frame.origin.x, -12)];
    
    
    self.centerNavigationBarView = (TMView *) centerTextField;
    
    weak();
    self.doneButton = [TMTextButton standartUserProfileNavigationButtonWithTitle:NSLocalizedString(@"Username.setName", nil)];
    [self.doneButton setTapBlock:^{
        
        
        [weakSelf showModalProgress];
        [[UsersManager sharedManager] updateUserName:((UserNameViewContainer *)weakSelf.view).checkedUserName completeHandler:^(TGUser *user) {
            
            [weakSelf hideModalProgress];
            
            
            [((UserNameViewContainer *)weakSelf.view) controlTextDidChange:nil];
        } errorHandler:^(NSString *error) {
            alert(error, error);
            [weakSelf hideModalProgress];
        }];
    }];
    
    [self.doneButton setDisableColor:NSColorFromRGB(0x999999)];
    
    TMView *rightView = [[TMView alloc] init];
    
    [rightView setFrameSize:self.doneButton.frame.size];
    
    
    [rightView addSubview:self.doneButton];
    
    [self setRightNavigationBarView:rightView animated:NO];
    
    ((UserNameViewContainer *)self.view).controller = self;
    
}





-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [((UserNameViewContainer *)self.view).textView.textView setStringValue:[UsersManager currentUser].user_name];
    [((UserNameViewContainer *)self.view) controlTextDidChange:nil];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [((UserNameViewContainer *)self.view).textView becomeFirstResponder];
    [((UserNameViewContainer *)self.view).textView.textView setSelectionRange:NSMakeRange(((UserNameViewContainer *)self.view).textView.textView.stringValue.length, 0)];
    
}

@end
