//
//  AppUser.h
//  uClip
//
//  Created by Hai Trieu on 1/14/15.
//  Copyright (c) 2015 Hai Trieu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppUser : NSObject

@property (nonatomic, assign) int uid;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayname;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, strong) NSDate *joinDate;
@property (nonatomic, assign) int fCoin;
@property (nonatomic, assign) BOOL isLogin;
@property (nonatomic, assign) int isService;
@property (nonatomic, assign) BOOL is3G;

@end
