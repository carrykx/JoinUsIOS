//
//  UpdateEmailViewController.m
//  JoinUs
//
//  Created by Liang Qian on 5/5/2016.
//  Copyright © 2016 North Gate Code. All rights reserved.
//

#import "UpdateEmailViewController.h"
#import "Utils.h"
#import "NetworkManager.h"

@interface UpdateEmailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *currentEmailLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *verifyCodeTextField;
@property (weak, nonatomic) IBOutlet UIButton *getVerifyCodeButton;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@end

@implementation UpdateEmailViewController{
    NSTimer* _timer;
    int _countDown;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.getVerifyCodeButton.layer.cornerRadius = 3;
    self.submitButton.layer.cornerRadius = 5;
    
    UserProfile* myProfile = [NetworkManager sharedManager].myProfile;
    if (myProfile.email != nil && myProfile.email.length > 0) {
        self.currentEmailLabel.text = myProfile.email;
    } else {
        self.currentEmailLabel.text = @"未设置";
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_timer != nil) {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)onTick {
    NSLog(@"Tick!");
    _countDown--;
    
    if (_countDown > 0) {
        [self.getVerifyCodeButton setTitle:[NSString stringWithFormat:@"重新获取(%ds)", _countDown] forState:UIControlStateDisabled];
        self.getVerifyCodeButton.enabled = NO;
        self.getVerifyCodeButton.backgroundColor = [UIColor lightGrayColor];
    } else if (_countDown == 0) {
        [self.getVerifyCodeButton setTitle:[NSString stringWithFormat:@"获取验证码"] forState:UIControlStateNormal];
        self.getVerifyCodeButton.enabled = YES;
        self.getVerifyCodeButton.backgroundColor = [UIColor colorWithRGBValue:0x00bbd5];
        [_timer invalidate];
        _timer = nil;
    }
}

- (IBAction)getVerifyCodeButtonPressed:(id)sender {
    self.getVerifyCodeButton.enabled = NO;
    self.getVerifyCodeButton.backgroundColor = [UIColor lightGrayColor];
    _countDown = 10;
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onTick) userInfo:nil repeats:YES];
    }
    
    [self.view makeToastActivity:CSToastPositionCenter];
    NSString* url = [NSString stringWithFormat:@"myProfile/updateEmailVerifyCode/%@", self.emailTextField.text];
    [[NetworkManager sharedManager] getDataWithUrl:url completionHandler:^(long statusCode, NSData *data, NSString *errorMessage) {
        [self.view hideToastActivity];
        if (statusCode == 200) {
            NSError* error;
            Message* msg = [[Message alloc] initWithData:data error:&error];
            if (error == nil) {
                [self.view makeToast:msg.message];
            } else {
                NSLog(@"JSON parsing error: %@", error);
            }
        } else {
            [self.view makeToast:errorMessage];
        }
    }];
}

- (IBAction)submitButtonPressed:(id)sender {
    
    if (self.emailTextField.text.length < 5 || self.verifyCodeTextField.text.length != 6) {
        [self.view makeToast:@"请输入有效的邮箱与验证码"];
        return;
    }
    
    EmailVerifyCode* emailVerifyCode = [[EmailVerifyCode alloc] init];
    emailVerifyCode.email = self.emailTextField.text;
    emailVerifyCode.verifyCode = self.verifyCodeTextField.text;
    
    [self.view makeToastActivity:CSToastPositionCenter];
    [[NetworkManager sharedManager] postDataWithUrl:@"myProfile/email" data:[emailVerifyCode toJSONData] completionHandler:^(long statusCode, NSData *data, NSString *errorMessage) {
        [self.view hideToastActivity];
        if (statusCode == 200) {
            NSError *error;
            UserProfile* myProfile = [[UserProfile alloc] initWithData:data error:&error];
            if (error == nil) {
            [[NetworkManager sharedManager] setMyProfile:myProfile];
            } else {
                NSLog(@"%@", error);
            }
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self.view makeToast:errorMessage];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
