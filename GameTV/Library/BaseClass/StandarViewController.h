//
//  StandarViewController.h
//  uClip
//
//  Created by Hai Trieu on 1/2/15.
//  Copyright (c) 2015 Hai Trieu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AFNetworking/AFNetworking.h>
#import "MarqueeLabel.h"
#import "OLGhostAlertView.h"
#import "NSMutableDictionary+UrlRequest.h"
#import "UIColor+Hex.h"
#import "Utils.h"
#import "CustomAds.h"

@import GoogleMobileAds;

enum {
    AdsTypeUnknown,
    AdsTypeGoogle,
    AdsTypeCustom,
};

typedef UInt32 AdsType;

enum {
    BRightBarSearch = 1,
    BRightBarDone = 2,
};
typedef UInt32 BRightBar;

@interface StandarViewController : UIViewController <UISearchBarDelegate,UIGestureRecognizerDelegate,GADInterstitialDelegate>{

    UIBarButtonItem *searchBarButtonItem;
    BRightBar buttonRightBarType;
    MarqueeLabel *lblTitle;
}

@property(nonatomic, weak) IBOutlet UIView *bannerView;
@property (strong, nonatomic) CustomAds *bannerCustomAds;
@property (strong, nonatomic) GADBannerView *bannerGoogleAds;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UIButton *hideSearchBar;
@property (nonatomic, strong) NSString *headerTitle;

-(void)doLoginWithUsername:(NSString*)username andPassword:(NSString*)password complete:(void(^)(id responseObject))completionBlock fail:(void(^)(id responseObject))failBlock;
-(void)showAds:(AdsType)type;
@end
