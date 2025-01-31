//
//  AppDelegate.h
//  GameTV
//
//  Created by Hai Trieu on 4/3/15.
//  Copyright (c) 2015 Hai Trieu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AppUser.h"
#import "IIViewDeckController.h"
#import "LeftViewController.h"
#import "CustomTabbar.h"
#import "BSVideoDetailController.h"
#import "StandarViewController.h"

@import GoogleMobileAds;

@interface AppDelegate : UIResponder <UIApplicationDelegate,GADInterstitialDelegate,RemoveViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) AppUser *user;
@property (nonatomic, strong) NSString *adUnitID;
@property (strong, nonatomic) NSArray *customAds;
@property (assign, nonatomic) AdsType adsType;
@property (nonatomic, strong) IIViewDeckController* deckController;
@property (nonatomic, strong) LeftViewController *leftViewController;
@property (strong, nonatomic) UINavigationController *liveController;
@property (strong, nonatomic) UINavigationController *homeController;
@property (strong, nonatomic) UINavigationController *scheduleController;
@property (nonatomic, strong) UINavigationController *loginViewController;
@property(nonatomic, strong) GADInterstitial *interstitial;

/*Tabbar*/
@property (nonatomic, strong) CustomTabbar *tabbar;
@property (nonatomic, assign) BOOL showTabbar;

/*Video detail*/
@property(nonatomic, strong) BSVideoDetailController *videoDetailViewController;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)showSecondControllerWithVideoId:(double)videoId;
- (void)showSecondControllerWithChannel:(Channel*)channel;
-(void)showLogin;
-(void)showInfo;
-(void)initAdmobFull;

@end

