//
//  LoginViewController.m
//  Sport
//
//  Created by Hai Trieu on 3/18/13.
//
//

#import "LoginViewController.h"
#import "RegisterViewController.h"
#import "OLGhostAlertView.h"
#import "ForgotPasswordViewController.h"
#import "ServiceViewController.h"
/*Demo
 test3@gmail.com/123456
 */
@interface LoginViewController ()

@end

@implementation LoginViewController

UITextField *_textField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    self.headerTitle = @"Đăng nhập";
    tableView.tableFooterView = footerView;
    tableView.tableHeaderView = self.bannerView;
    
    UIColor *backGroundColor = [[UIColor alloc]initWithRed:1.0 green:1.0 blue:1.0  alpha:0.1];
    UIView *bview = [[UIView alloc]initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width)];
    [bview setBackgroundColor:backGroundColor];
    [tableView setBackgroundColor:[UIColor clearColor]];
    [tableView setBackgroundView:bview];
    
    isRememberPassword = YES;
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    username.text = [standardUserDefaults objectForKey:@"TmpUserName"];
    password.text = [standardUserDefaults objectForKey:@"TmpPassword"];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)signinBtnPress:(id)sender{
    [_textField resignFirstResponder];
//    self.navigationItem.leftBarButtonItem.enabled = YES;
    if (![self validateForm]) {
        return;
    }
    [_textField resignFirstResponder];
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    if (isRememberPassword) {

        
        [standardUserDefaults setObject:username.text forKey:@"TmpUserName"];
        [standardUserDefaults setObject:password.text forKey:@"TmpPassword"];
        

    }
    else{
        [standardUserDefaults removeObjectForKey:@"TmpUserName"];
        [standardUserDefaults removeObjectForKey:@"TmpPassword"];
    }
    
    [standardUserDefaults synchronize];
    
    [self doLoginWithUsername:username.text andPassword:password.text complete:^(id responseObject) {

        [self dismissViewControllerAnimated:YES completion:nil];
        
    } fail:^(id responseObject) {
        [self dismissViewControllerAnimated:YES completion:nil];        
    }];

}

-(IBAction)singupBtnPress:(id)sender{
    
    [self showSignUpForm];
    
}

-(IBAction)forgotBtnPress:(id)sender{
    ForgotPasswordViewController *forgotPasswordViewController = [[ForgotPasswordViewController alloc] initWithNibName:@"ForgotPasswordViewController" bundle:nil];
    [self.navigationController pushViewController:forgotPasswordViewController animated:YES];

}

-(IBAction)rememberPassPress:(id)sender{
    isRememberPassword = !isRememberPassword;
    if (isRememberPassword) {
        [rememberPassword setImage:[UIImage imageNamed:@"check"] forState:UIControlStateNormal];
    }
    else{
        [rememberPassword setImage:[UIImage imageNamed:@"login_checkbox.png"] forState:UIControlStateNormal];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return usrCell;
    }
    else{
        return pwdCell;
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    _textField = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
//    self.navigationItem.leftBarButtonItem.enabled = YES;
    [_textField resignFirstResponder];
    return YES;
}

-(BOOL)validateForm{
    NSMutableString *errorMsg = [[NSMutableString alloc] init];
    if ([username.text length] < 6) {
        [errorMsg appendFormat:@"Số điện thoại không hợp lệ\n"];
    }
    if ([password.text length] < 6) {
        [errorMsg appendFormat:@"Mật khẩu không hợp lệ\n"];
    }
    if ([errorMsg length] > 0) {
        OLGhostAlertView *alertView = [[OLGhostAlertView alloc] initWithTitle:errorMsg];
        [alertView show];
        return NO;
    }
    return YES;
}

- (void)mSportDidLoginWithUsername:(NSString*)username andPassword:(NSString*)password{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
//    if (SharedAppDelegate.user.isService) {
//        [self dismissViewControllerAnimated:YES completion:^{
//            
//        }];
//    }
//    else{
//        ServiceViewController *serviceView = [[ServiceViewController alloc] initWithNibName:@"ServiceViewController" bundle:nil];
//        
//        [self.navigationController pushViewController:serviceView animated:YES];
//    }
}

-(void)showSignUpForm{

   RegisterViewController *regisController = [[RegisterViewController alloc] initWithNibName:@"RegisterViewController" bundle:nil];
   [self.navigationController pushViewController:regisController animated:YES];

}

-(IBAction)enterNoLogin:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
