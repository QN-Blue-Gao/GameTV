//
//  BSVideoDetailController.m
//  YouTubeDraggableVideo
//
//  Created by Sandeep Mukherjee on 02/02/15.
//  Copyright (c) 2015 Sandeep Mukherjee. All rights reserved.
//


#import "BSVideoDetailController.h"
#import "QuartzCore/CALayer.h"
#import "SinglePlayer.h"
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import "HeaderMenu.h"

#define LABEL_WIDTH 300

static void *MyStreamingMovieViewControllerTimedMetadataObserverContext = &MyStreamingMovieViewControllerTimedMetadataObserverContext;
static void *MyStreamingMovieViewControllerRateObservationContext = &MyStreamingMovieViewControllerRateObservationContext;
static void *MyStreamingMovieViewControllerCurrentItemObservationContext = &MyStreamingMovieViewControllerCurrentItemObservationContext;
static void *MyStreamingMovieViewControllerPlayerItemStatusObserverContext = &MyStreamingMovieViewControllerPlayerItemStatusObserverContext;

NSString *kTracksKey		= @"tracks";
NSString *kStatusKey		= @"status";
NSString *kRateKey			= @"rate";
NSString *kPlayableKey		= @"playable";
NSString *kCurrentItemKey	= @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";



@interface BSVideoDetailController (Player) 

- (CMTime)playerItemDuration;
- (BOOL)isPlaying;
- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata;
- (void)updateAdList:(NSArray *)newAdList;
- (void)assetFailedToPrepareForPlayback:(NSError *)error;
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys;
- (void)removePlayerTimeObserver;
- (void)removePlayerObserver;

@end

@implementation BSVideoDetailController 
{

    //local Frame store
    CGRect youtubeFrame;
    CGRect tblFrame;
    CGRect menuFrame;
    CGRect viewFrame;
    CGRect minimizedYouTubeFrame;
    CGRect growingTextViewFrame;;
    
    //local touch location
    CGFloat _touchPositionInHeaderY;
    CGFloat _touchPositionInHeaderX;
    
    //local restriction Offset--- for checking out of bound
    float restrictOffset,restrictTrueOffset,restictYaxis;
    
    //detecting Pan gesture Direction
    UIPanGestureRecognizerDirection direction;
    
    //Creating a transparent Black layer view
    UIView *transaparentVw;
    
    //Just to Check wether view  is expanded or not
    BOOL isExpandedMode;
    
}

@synthesize playerLayerView,playerItem;



- (void)viewDidLoad {
    [super viewDidLoad];

    [[UIApplication sharedApplication] setStatusBarHidden:YES
                                            withAnimation:UIStatusBarAnimationFade];
    [self toggleShowHideControls:NO];
    ipAddress.text = SharedAppDelegate.user.ipAddress;
    
    //Online video from youtube
    if (_videoId  > 0) {
        _isLive = NO;
        _currentC = 0;
        [self performSelector:@selector(youtubePlay) withObject:nil afterDelay:0.8];
    }
    //Live video from F5 Server
    else{
        _isLive = YES;
        [self performSelector:@selector(livePlay) withObject:nil afterDelay:0.8];
    }

    //adding Pan Gesture
    pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panAction:)];
    pan.delegate=self;
    [self.viewYouTube addGestureRecognizer:pan];
    isExpandedMode=TRUE;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showHideControl:)];
    [uvControls addGestureRecognizer:tapRecognizer];
    
    self.tblView.tableHeaderView = self.viewShare;
}

#pragma mark- Status Bar Hidden function

- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (NSUInteger) supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
    
}
- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark- Add Video on View
-(void)livePlay{
    
    if ([SinglePlayer sharedInstance].player.rate == 1.0) {
        [[SinglePlayer sharedInstance].player pause];
    }

    _lblMatchName.text =  _channel.name;
    [self playVideoWithURL:[NSURL URLWithString:_channel.channelUrl]];
    [self addVideo];
    
}

-(void)youtubePlay{

    if ([SinglePlayer sharedInstance].player.rate == 1.0) {
        [[SinglePlayer sharedInstance].player pause];
    }
    
    NSString *urlRequest = [NSString stringWithFormat:@"%@post&id=%0.f",kDomain,_videoId];
    NSLog(@"url request is %@",urlRequest);
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:urlRequest parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"video detail is %@",responseObject);
        _videoDetail = [responseObject objectForKey:@"data"];
        _lblMatchName.text = [_videoDetail objectForKey:@"title"];
        _lblDate.text = [_videoDetail objectForKey:@"date"];
        [self.tblView reloadData];
        [self playYoutubeLink:[[[[_videoDetail objectForKey:@"set"] objectAtIndex:0] objectForKey:@"list"] objectAtIndex:0]];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        
    }];

    [self addVideo];
}

-(void)playYoutubeLink:(NSString*)youtubeLink{

    NSString* videoId = [self getYoutubeId:youtubeLink];
    NSLog(@"video id is %@",videoId);
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:videoId completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
            NSDictionary *streamURLs = video.streamURLs;
            NSURL *url = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
            [self playVideoWithURL:url];
        }
        else
        {
            
        }
    }];
}

-(NSString*)getYoutubeId:(NSString*)youtubeLink{
    NSError *error = NULL;
    NSRegularExpression *regex =
    [NSRegularExpression regularExpressionWithPattern:@"(?:youtube.com.+v[=/]|youtu.be/)([-a-zA-Z0-9_]+)"
                                              options:NSRegularExpressionCaseInsensitive
                                                error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:youtubeLink
                                                    options:0
                                                      range:NSMakeRange(0, [youtubeLink length])];
    if (match) {
        NSRange videoIDRange = [match rangeAtIndex:1];
        return [youtubeLink substringWithRange:videoIDRange];
    }
    return @"";
}

-(void)addVideo
{
    playerLayerView = [[MyPlayerLayerView alloc] init];
    CGRect rect = self.viewYouTube.frame;
    NSLog(@"rect is %f %f %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
    playerLayerView.frame = self.viewYouTube.frame;
    [self.viewYouTube insertSubview:playerLayerView belowSubview:uvControls];
    [self calculateFrames];

}


-(void)playVideoWithURL:(NSURL*)url{
    if ([url scheme])
    {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
        NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
        [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
         ^{
             dispatch_async( dispatch_get_main_queue(),
                            ^{
                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                            });
         }];
    }
}

#pragma mark- Calculate Frames and Store Frame Size
-(void)calculateFrames
{
    youtubeFrame=self.viewYouTube.frame;
    tblFrame=self.viewTable.frame;
    
    self.viewYouTube.translatesAutoresizingMaskIntoConstraints = YES;
    self.viewTable.translatesAutoresizingMaskIntoConstraints = YES;
    CGRect frame=self.viewGrowingTextView.frame;
    growingTextViewFrame=self.viewGrowingTextView.frame;
    self.viewGrowingTextView.translatesAutoresizingMaskIntoConstraints = YES;
    self.viewGrowingTextView.frame=frame;
    frame=self.txtViewGrowing.frame;
    self.txtViewGrowing.translatesAutoresizingMaskIntoConstraints = YES;
    self.txtViewGrowing.frame=frame;

    self.viewYouTube.frame=youtubeFrame;
    self.viewTable.frame=tblFrame;
    menuFrame=self.viewTable.frame;
    viewFrame=self.viewYouTube.frame;
    
    restrictOffset=self.initialFirstViewFrame.size.width-200;
    restrictTrueOffset = self.initialFirstViewFrame.size.height - 180;
    restictYaxis=self.initialFirstViewFrame.size.height-self.viewYouTube.frame.size.height;

    self.view.hidden=TRUE;
    transaparentVw=[[UIView alloc]initWithFrame:self.initialFirstViewFrame];
    transaparentVw.backgroundColor=[UIColor blackColor];
    transaparentVw.alpha=0.9;
    [self.onView addSubview:transaparentVw];
    
    [self.onView addSubview:self.viewTable];
    [self.onView addSubview:self.viewYouTube];
    [self stGrowingTextViewProperty];
//    [self.playerLayerView addSubview:self.btnDown];
    

    [[Utils shareInstance] hideLoadingView];
    //animate Button Down
    self.btnDown.translatesAutoresizingMaskIntoConstraints = YES;
    self.btnDown.frame=CGRectMake( self.btnDown.frame.origin.x,  self.btnDown.frame.origin.y-22,  self.btnDown.frame.size.width,  self.btnDown.frame.size.width);
    CGRect frameBtnDown=self.btnDown.frame;
    
    [UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat|UIViewAnimationOptionAllowUserInteraction animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.btnDown.transform=CGAffineTransformMakeScale(1.5, 1.5);
            
            [self addShadow];
            self.btnDown.frame=CGRectMake(frameBtnDown.origin.x, frameBtnDown.origin.y+17, frameBtnDown.size.width, frameBtnDown.size.width);
            
            
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            self.btnDown.frame=CGRectMake(frameBtnDown.origin.x, frameBtnDown.origin.y, frameBtnDown.size.width, frameBtnDown.size.width);
            self.btnDown.transform=CGAffineTransformIdentity;
            [self addShadow];
        }];
    } completion:nil];
    
}

-(void)addShadow
{
    self.btnDown.imageView.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.btnDown.imageView.layer.shadowOffset = CGSizeMake(0, 1);
    self.btnDown.imageView.layer.shadowOpacity = 1;
    self.btnDown.imageView.layer.shadowRadius = 4.0;
    self.btnDown.imageView.clipsToBounds = NO;
}


#pragma mark- Pan Gesture Delagate

- (BOOL)gestureRecognizerShould:(UIGestureRecognizer *)gestureRecognizer {
    
    if(gestureRecognizer.view.frame.origin.y<0)
    {
        return NO;
    }
    return YES;
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark- Tap Gesture Selector Action

-(void)showHideControl:(UITapGestureRecognizer*)gestureRecognizer{
    [self toggleShowHideControls:!isControlShow];
}

-(void)toggleShowHideControls:(BOOL)show{
    ipAddress.center = [self randomPointInRect:self.viewYouTube.frame];
    isControlShow = show;
    if (!isControlShow) {
        [UIView animateWithDuration:0.5f animations:
         ^{
             playBtn.alpha = 0;
             stopBtn.alpha = 0;
             movieTimeControl.alpha = 0;
             currentTime.alpha = 0;
             remainTime.alpha = 0;
             fullScreenBtn.alpha = 0;
             uvBgControls.alpha = 0;
             self.btnDown.alpha = 0;

         } completion:
         ^(BOOL finished)
         {

         }];
    }
    else{
        [UIView animateWithDuration:0.5f animations:
         ^{
             playBtn.alpha = 1;
             stopBtn.alpha = 1;
             movieTimeControl.alpha = 1;
             currentTime.alpha = 1;
             remainTime.alpha = 1;
             fullScreenBtn.alpha = 1;
             uvBgControls.alpha = 0.5;
             self.btnDown.alpha = 1;
             
         } completion:^(BOOL finished){}];
    }
}

#pragma mark- Pan Gesture Selector Action

-(void)panAction:(UIPanGestureRecognizer *)recognizer
{
    
    CGFloat y = [recognizer locationInView:self.view].y;
    
    if(recognizer.state == UIGestureRecognizerStateBegan){
        
        direction = UIPanGestureRecognizerDirectionUndefined;
        //storing direction
        CGPoint velocity = [recognizer velocityInView:recognizer.view];
        [self detectPanDirection:velocity];

        _touchPositionInHeaderY = [recognizer locationInView:self.viewYouTube].y;
        _touchPositionInHeaderX = [recognizer locationInView:self.viewYouTube].x;
        if(direction==UIPanGestureRecognizerDirectionDown)
        {
            
        }
        
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged){
        
        
        if(direction==UIPanGestureRecognizerDirectionDown || direction==UIPanGestureRecognizerDirectionUp)
        {
            
            CGFloat trueOffset = y - _touchPositionInHeaderY;
            CGFloat xOffset = (y - _touchPositionInHeaderY)*0.35;
            [self adjustViewOnVerticalPan:trueOffset :xOffset recognizer:recognizer];
            
        }
        else if (direction==UIPanGestureRecognizerDirectionRight || direction==UIPanGestureRecognizerDirectionLeft)
        {
            [self adjustViewOnHorizontalPan:recognizer];
        }
        
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded){
        
        if(direction==UIPanGestureRecognizerDirectionDown || direction==UIPanGestureRecognizerDirectionUp)
        {
            
            if(recognizer.view.frame.origin.y<0)
            {
                [self expandViewOnPan];
                
                [recognizer setTranslation:CGPointZero inView:recognizer.view];
                
                return;
                
            }
            else if(recognizer.view.frame.origin.y>(self.initialFirstViewFrame.size.width/2))
            {
                
                [self minimizeViewOnPan];
                [recognizer setTranslation:CGPointZero inView:recognizer.view];
                return;
                
                
            }
            else if(recognizer.view.frame.origin.y<(self.initialFirstViewFrame.size.width/2))
            {
                [self expandViewOnPan];
                [recognizer setTranslation:CGPointZero inView:recognizer.view];
                return;
                
            }
        }
        
        else if (direction==UIPanGestureRecognizerDirectionLeft)
        {
            if(self.viewTable.alpha<=0)
            {
                
                if(recognizer.view.frame.origin.x<0)
                {
                    [self.view removeFromSuperview];
                    [self removeView];
                    [self.delegate removeController];
                    
                }
                else
                {
                    [self animateViewToRight:recognizer];
                    
                }
            }
        }
        
        else if (direction==UIPanGestureRecognizerDirectionRight)
        {
            if(self.viewTable.alpha<=0)
            {
                
                
                if(recognizer.view.frame.origin.x>self.initialFirstViewFrame.size.width-50)
                {
                    [self.view removeFromSuperview];
                    [self removeView];
                    [self.delegate removeController];
                    
                }
                else
                {
                    [self animateViewToLeft:recognizer];
                    
                }
            }
        }
        
        
    }
    
}


-(IBAction)showFullScreen:(id)sender{
    [self toggleVideoFullScreen];
}


-(void)toggleVideoFullScreen{
    if (isFullScreen) {
        isFullScreen = NO;
        pan.enabled = YES;
        [UIView animateWithDuration:0.2 animations:^{
            [fullScreenBtn setImage:[UIImage imageNamed:@"player_full.png"] forState:UIControlStateNormal];
            UIView *rootView = SharedAppDelegate.window;
            self.navigationController.view.frame = CGRectMake(rootView.frame.origin.x,rootView.frame.origin.y,rootView.frame.size.width,rootView.frame.size.height);
            self.viewYouTube.transform = CGAffineTransformMakeRotation(0);
            self.viewYouTube.frame = minimizeRect;
            playerLayerView.frame = minimizeRect;
            [rootView addSubview:self.viewYouTube];
            self.btnDown.hidden = NO;
        }];
    }
    else{
        isFullScreen = YES;
        pan.enabled = NO;
        [UIView animateWithDuration:0.2 animations:^{
            [fullScreenBtn setImage:[UIImage imageNamed:@"minimize-button"] forState:UIControlStateNormal];
            minimizeRect = self.viewYouTube.frame;
            UIView *rootView = SharedAppDelegate.window;
            [rootView setBackgroundColor:[UIColor whiteColor]];
            [rootView addSubview:self.viewYouTube];
            rootView.frame = SharedAppDelegate.window.bounds;
            self.viewYouTube.frame = CGRectMake(0, 0, rootView.frame.size.height, rootView.frame.size.width);
            self.viewYouTube.transform = CGAffineTransformMakeRotation(M_PI/2);
            self.viewYouTube.center = rootView.center;
            playerLayerView.frame = CGRectMake(0, 0, self.viewYouTube.frame.size.height, self.viewYouTube.frame.size.width);
            uvControls.frame = playerLayerView.frame;
            self.btnDown.hidden = YES;
            fullScreenBtn.contentEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
            
        }];
        
    }
}

- (CGPoint)randomPointInRect:(CGRect)rect{
    int minX = ipAddress.frame.size.width/2;
    int maxX = rect.size.width - ipAddress.frame.size.width/2;
    int minY = ipAddress.frame.size.height/2;
    int maxY = rect.size.height - ipAddress.frame.size.height/2;
    int centerX = (arc4random() % (maxX - minX)) + minX;
    int centerY = (arc4random() % (maxY - minY)) + minY;
    return CGPointMake(centerX, centerY);
}

#pragma mark - Keyboard events

//Handling the keyboard appear and disappering events

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    //__weak typeof(self) weakSelf = self;
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         float yPosition=self.view.frame.size.height- kbSize.height- self.viewGrowingTextView.frame.size.height;
                         self.viewGrowingTextView.frame=CGRectMake(0, yPosition, self.viewGrowingTextView.frame.size.width, self.viewGrowingTextView.frame.size.height);
                         
                     }
                     completion:^(BOOL finished) {
                     }];
    
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         float yPosition=self.view.frame.size.height-self.viewGrowingTextView.frame.size.height;
                         self.viewGrowingTextView.frame=CGRectMake(0, yPosition, self.viewGrowingTextView.frame.size.width, self.viewGrowingTextView.frame.size.height);
                     }
                     completion:^(BOOL finished) {
                     }];
}
#pragma mark -
#pragma mark - Text View delegate -

#pragma mark- View Function Methods
-(void)stGrowingTextViewProperty
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIContentSizeCategoryDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
}

-(void)animateViewToRight:(UIPanGestureRecognizer *)recognizer{
    [self.txtViewGrowing resignFirstResponder];
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         self.viewTable.frame = menuFrame;
                         self.viewYouTube.frame=viewFrame;
                         playerLayerView.frame = CGRectMake( playerLayerView.frame.origin.x,  playerLayerView.frame.origin.x, viewFrame.size.width, viewFrame.size.height);
                         self.viewTable.alpha=0;
                         uvControls.alpha = 0;
                         self.viewYouTube.alpha=1;
                         
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    [recognizer setTranslation:CGPointZero inView:recognizer.view];
    
}

-(void)animateViewToLeft:(UIPanGestureRecognizer *)recognizer{
    [self.txtViewGrowing resignFirstResponder];
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         self.viewTable.frame = menuFrame;
                         self.viewYouTube.frame = viewFrame;
                         playerLayerView.frame = CGRectMake( playerLayerView.frame.origin.x,  playerLayerView.frame.origin.x, viewFrame.size.width, viewFrame.size.height);
                         self.viewTable.alpha=0;
                         uvControls.alpha = 0;
                         self.viewYouTube.alpha=1;
                         
                         
                         
                     }
                     completion:^(BOOL finished) {
                         
                     }];
    
    [recognizer setTranslation:CGPointZero inView:recognizer.view];
    
}


-(void)adjustViewOnHorizontalPan:(UIPanGestureRecognizer *)recognizer {
    [self.txtViewGrowing resignFirstResponder];
    CGFloat x = [recognizer locationInView:self.view].x;
    
    if (direction==UIPanGestureRecognizerDirectionLeft)
    {
        if(self.viewTable.alpha<=0)
        {
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            
            BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
            
            
            
            CGPoint translation = [recognizer translationInView:recognizer.view];
            
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                                 recognizer.view.center.y );
            
            
            if (!isVerticalGesture) {
                
                CGFloat percentage = (x/self.initialFirstViewFrame.size.width);
                
                recognizer.view.alpha = percentage;
                
            }
            
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
        }
    }
    else if (direction==UIPanGestureRecognizerDirectionRight)
    {
        if(self.viewTable.alpha<=0)
        {
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            
            BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
            
            
            
            CGPoint translation = [recognizer translationInView:recognizer.view];
            
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                                 recognizer.view.center.y );
            
            
            if (!isVerticalGesture) {
                
                if(velocity.x > 0)
                {
                    
                    CGFloat percentage = (x/self.initialFirstViewFrame.size.width);
                    recognizer.view.alpha =1.0- percentage;                }
                else
                {
                    CGFloat percentage = (x/self.initialFirstViewFrame.size.width);
                    recognizer.view.alpha =percentage;
                    
                    
                }
                
            }
            
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
        }
    }
}

-(void)adjustViewOnVerticalPan:(CGFloat)trueOffset :(CGFloat)xOffset recognizer:(UIPanGestureRecognizer *)recognizer
{
    [self.txtViewGrowing resignFirstResponder];
    CGFloat y = [recognizer locationInView:self.view].y;
    
    if(trueOffset>=restrictTrueOffset+60||xOffset>=restrictOffset+60)
    {
        CGFloat trueOffset = self.initialFirstViewFrame.size.height - 100;
        CGFloat xOffset = self.initialFirstViewFrame.size.width-160;
        //Use this offset to adjust the position of your view accordingly
        menuFrame.origin.y = trueOffset;
        menuFrame.origin.x = xOffset;
        menuFrame.size.width=self.initialFirstViewFrame.size.width-xOffset;
        
        viewFrame.size.width=self.view.bounds.size.width-xOffset;
        viewFrame.size.height=200-xOffset*0.5;
        viewFrame.origin.y=trueOffset;
        viewFrame.origin.x=xOffset;
        
        [UIView animateWithDuration:0.05
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^ {
                             self.viewTable.frame = menuFrame;
                             self.viewYouTube.frame=viewFrame;
                             playerLayerView.frame = CGRectMake( playerLayerView.frame.origin.x,  playerLayerView.frame.origin.x, viewFrame.size.width, viewFrame.size.height);
                             self.viewTable.alpha=0;
                             uvControls.alpha = 0;
                             
                             
                         }
                         completion:^(BOOL finished) {
                             minimizedYouTubeFrame=self.viewYouTube.frame;
                             
                             isExpandedMode=FALSE;
                         }];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
        
    }
    else
    {
        
        //Use this offset to adjust the position of your view accordingly
        menuFrame.origin.y = trueOffset;
        menuFrame.origin.x = xOffset;
        menuFrame.size.width=self.initialFirstViewFrame.size.width-xOffset;
        viewFrame.size.width=self.view.bounds.size.width-xOffset;
        viewFrame.size.height=200-xOffset*0.5;
        viewFrame.origin.y=trueOffset;
        viewFrame.origin.x=xOffset;
        float restrictY=self.initialFirstViewFrame.size.height-self.viewYouTube.frame.size.height-10;
        
        
        if (self.viewTable.frame.origin.y<restrictY && self.viewTable.frame.origin.y>0) {
            [UIView animateWithDuration:0.09
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^ {
                                 self.viewTable.frame = menuFrame;
                                 self.viewYouTube.frame=viewFrame;
                                 playerLayerView.frame = CGRectMake( playerLayerView.frame.origin.x,  playerLayerView.frame.origin.x, viewFrame.size.width, viewFrame.size.height);
                                 
                                 CGFloat percentage = y/self.initialFirstViewFrame.size.height;
                                 self.viewTable.alpha = transaparentVw.alpha = 1.0 - percentage;
                                 
                                 
                                 
                                 
                             }
                             completion:^(BOOL finished) {
                                 if(direction==UIPanGestureRecognizerDirectionDown)
                                 {
                                     [self.onView bringSubviewToFront:self.view];
                                 }
                             }];
        }
        else if (menuFrame.origin.y<restrictY&& menuFrame.origin.y>0)
        {
            [UIView animateWithDuration:0.09
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^ {
                                 self.viewTable.frame = menuFrame;
                                 self.viewYouTube.frame=viewFrame;
                                 playerLayerView.frame = CGRectMake( playerLayerView.frame.origin.x,  playerLayerView.frame.origin.x, viewFrame.size.width, viewFrame.size.height);
                             }completion:nil];
            
            
        }
        
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
    
}
-(void)detectPanDirection:(CGPoint )velocity
{
    self.btnDown.hidden=TRUE;
    BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
    
    if (isVerticalGesture) {
        if (velocity.y > 0) {
            direction = UIPanGestureRecognizerDirectionDown;
            
        } else {
            direction = UIPanGestureRecognizerDirectionUp;
        }
    }
    else
        
    {
        if(velocity.x > 0)
        {
            direction = UIPanGestureRecognizerDirectionRight;
        }
        else
        {
            direction = UIPanGestureRecognizerDirectionLeft;
        }
        
    }
    
}

- (void)expandViewOnTap:(UITapGestureRecognizer*)sender {
    
    [self expandViewOnPan];
    for (UIGestureRecognizer *recognizer in self.viewYouTube.gestureRecognizers) {
        
        if([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            [self.viewYouTube removeGestureRecognizer:recognizer];
        }
    }
    
}

-(void)minimizeViewOnPan
{
    self.btnDown.hidden=TRUE;
    [self.txtViewGrowing resignFirstResponder];
    CGFloat trueOffset = self.initialFirstViewFrame.size.height - 50;
    CGFloat xOffset = self.initialFirstViewFrame.size.width-160;
    //Use this offset to adjust the position of your view accordingly
    menuFrame.origin.y = trueOffset;
    menuFrame.origin.x = xOffset;
    menuFrame.size.width=self.initialFirstViewFrame.size.width-xOffset;
    viewFrame.size.width=self.view.bounds.size.width-xOffset;
    viewFrame.size.height= 120; // 200-xOffset*0.5;
    viewFrame.origin.y=trueOffset - 80;
    viewFrame.origin.x=xOffset;
//    NSLog(@"true xoffset %f %f",trueOffset,xOffset);
//    NSLog(@"self.initialFirstView frame %@",NSStringFromCGRect(self.initialFirstViewFrame));
//    NSLog(@"view frame %@",NSStringFromCGRect(viewFrame));
//    NSLog(@"menu frame %@",NSStringFromCGRect(menuFrame));
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         self.viewTable.frame = menuFrame;
                         self.viewYouTube.frame = viewFrame;
                         playerLayerView.frame = CGRectMake(playerLayerView.frame.origin.x,  playerLayerView.frame.origin.x, viewFrame.size.width, viewFrame.size.height);
//                         playerLayerView.frame = viewFrame;
                         self.viewTable.alpha=0;
                         transaparentVw.alpha=0.0;
                         [self toggleShowHideControls:NO];
                         [[UIApplication sharedApplication] setStatusBarHidden:NO
                                                                 withAnimation:UIStatusBarAnimationNone];
                         [UIApplication sharedApplication].keyWindow.windowLevel = UIWindowLevelNormal;
                     }
                     completion:^(BOOL finished) {
                         //add tap gesture
                         self.tapRecognizer=nil;
                         if(self.tapRecognizer==nil)
                         {
                             self.tapRecognizer= [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(expandViewOnTap:)];
                             self.tapRecognizer.numberOfTapsRequired=1;
                             self.tapRecognizer.delegate=self;
                             [self.viewYouTube addGestureRecognizer:self.tapRecognizer];
                         }
                         isExpandedMode=FALSE;
                         minimizedYouTubeFrame=self.viewYouTube.frame;
                         if(direction==UIPanGestureRecognizerDirectionDown)
                         {
                             [self.onView bringSubviewToFront:self.view];
                         }
                     }];
}

-(void)expandViewOnPan
{
    [self.txtViewGrowing resignFirstResponder];
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^ {
                         self.viewTable.frame = tblFrame;
                         self.viewYouTube.frame=youtubeFrame;
                         self.viewYouTube.alpha=1;
                         playerLayerView.frame = youtubeFrame;
                         self.viewTable.alpha=1.0;
                         uvControls.alpha = 1.0;
                         transaparentVw.alpha=1.0;
                         [self toggleShowHideControls:YES];
                         [[UIApplication sharedApplication] setStatusBarHidden:YES
                                                                 withAnimation:UIStatusBarAnimationNone];
                         [UIApplication sharedApplication].keyWindow.windowLevel = UIWindowLevelStatusBar;

                     }
                     completion:^(BOOL finished) {

                         isExpandedMode=TRUE;
                         self.btnDown.hidden=FALSE;
                     }];
    
    
    
}

-(void)removeView
{
    [[SinglePlayer sharedInstance].player pause];
    [self removePlayerTimeObserver];
    [self removePlayerObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [SinglePlayer sharedInstance].player = nil;
    [playerLayerView removeFromSuperview];
    [self setPlayerLayerView:nil];
    [self.viewYouTube removeFromSuperview];
    [self.viewTable removeFromSuperview];
    [transaparentVw removeFromSuperview];
}

#pragma mark - UITableViewDataSource
// number of section(s), now I assume there is only 1 section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView
{
    return _isLive ? 1 : 3;
}

// number of row in the section, I assume there is only 1 row
- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == (_isLive ? 0 : 2)) {

        return (_webViewDisplay.frame.size.height);
        
    }
    
    return 44;
    
}

- (CGFloat)minHeightForText:(NSString *)_text {
    if (!_textFont) {
        self.textFont = [UIFont boldSystemFontOfSize:16];
    }
    
    return [_text sizeWithFont:_textFont constrainedToSize:CGSizeMake(LABEL_WIDTH, 999999)
            lineBreakMode:NSLineBreakByWordWrapping
            ].height;
}


- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    CGRect frame = aWebView.frame;
    frame.size.height = 1;
    aWebView.frame = frame;
    // Asks the view to calculate and return the size that best fits its subviews.
    CGSize fittingSize = [aWebView sizeThatFits:CGSizeZero];
    frame.size = fittingSize;
    aWebView.frame = frame;
    [self.tblView beginUpdates];
    [self.tblView  endUpdates];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    HeaderMenu *header;
    NSArray *xibArray = [[NSBundle mainBundle] loadNibNamed:@"HeaderMenu" owner:nil options:nil];
    for (id xibObject in xibArray) {
        if ([xibObject isKindOfClass:[HeaderMenu class]]) {
            header = (HeaderMenu *)xibObject;
        }
    }
    if (section == 0 + (_isLive ? 0 : 2)) {
        header.sectionTitle = @"Chi tiết";
    }
    else if (!_isLive && section == 0) {
        header.sectionTitle = @"Danh sách C";
    }
    else if(section == 1){
        header.sectionTitle = @"Danh sách trận";
    }

    
    return header;
}

// the cell will be returned to the tableView
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == ( _isLive ? 0 : 2)) {
        static NSString * webIndentifier = @"ShowPageIdentifier";
        ShowPageCell *showCell = (ShowPageCell *)[theTableView dequeueReusableCellWithIdentifier:webIndentifier];
        
        if (showCell == nil) {
            [[NSBundle mainBundle] loadNibNamed:@"ShowPageCell" owner:self options:nil];
            showCell = showPageCell;
        }
        
        _webViewDisplay = [[UIWebView alloc] initWithFrame:CGRectMake(5.0f, 0.0f, self.view.frame.size.width, [self minHeightForText:[_videoDetail objectForKey:@"summary"]])];
        [_webViewDisplay loadHTMLString:[_videoDetail objectForKey:@"summary"] baseURL:nil];
        _webViewDisplay.delegate = self;
        _webViewDisplay.layer.cornerRadius = 0;
        _webViewDisplay.userInteractionEnabled = YES;
        _webViewDisplay.multipleTouchEnabled = YES;
        _webViewDisplay.clipsToBounds = YES;
        _webViewDisplay.scalesPageToFit = NO;
        _webViewDisplay.backgroundColor = [UIColor clearColor];
        _webViewDisplay.scrollView.scrollEnabled = NO;
        _webViewDisplay.scrollView.bounces = NO;
        [showCell addSubview:_webViewDisplay];
        
        return showCell;
    }
    else{
        static NSString *CellIdentifier = @"SetCell";
        SetCell* cell = (SetCell *)[theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (!cell) {
            NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"SetCell" owner:nil options:nil];
            for (id obj in nibArray) {
                if ([obj isMemberOfClass:[SetCell class]]) {
                    // Assign cell to obj
                    cell = (SetCell *)obj;
                    cell.delegate = self;
                    break;
                }
            }
        }
        if (indexPath.section == 0) {
            cell.prefix = @"C";
            cell.type = EpisodeTypeC;
            cell.sets = [_videoDetail objectForKey:@"set"];
        }
        else{
            cell.prefix = @"Trận";
            cell.type = EpisodeTypeMatch;
            cell.sets = [[[_videoDetail objectForKey:@"set"] objectAtIndex:0] objectForKey:@"list"];
        }
        
        return cell;
    }
}

#pragma mark - SetCellDelegate

-(void)didSelect:(SetCell*)cell atIndex:(int)index{

    NSArray *matches;
    if (cell.type == EpisodeTypeC) {
        _currentC = index;
        matches = [[[_videoDetail objectForKey:@"set"] objectAtIndex:index] objectForKey:@"list"];
        NSLog(@"did select c index %d and match %@",index,matches);
        [self playYoutubeLink:[matches objectAtIndex:0]];
    }
    else{
        matches = [[[_videoDetail objectForKey:@"set"] objectAtIndex:_currentC] objectForKey:@"list"];
        NSLog(@"did select match index %d and match is %@",index,[matches objectAtIndex:index]);
        [self playYoutubeLink:[matches objectAtIndex:index]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Action
- (IBAction)btnDownTapAction:(id)sender {
    
    [self minimizeViewOnPan];
    
}
- (IBAction)btnSendAction:(id)sender {
    [self.txtViewGrowing resignFirstResponder];
    self.txtViewGrowing.text=@"";
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         
                         self.viewGrowingTextView.frame=growingTextViewFrame;
                     }completion:^(BOOL finished) {
                         
                     }];
    
}

@end


@implementation BSVideoDetailController (Player)

#pragma mark -

#pragma mark Player

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)playerItemDuration
{
    AVPlayerItem *thePlayerItem = [[SinglePlayer sharedInstance].player currentItem];
    if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
    {
        
        return([playerItem duration]);
    }
    
    return(kCMTimeInvalid);
}

- (BOOL)isPlaying
{
    return restoreAfterScrubbingRate != 0.f || [[SinglePlayer sharedInstance].player rate] != 0.f;
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void) playerItemDidReachEnd:(NSNotification*) aNotification
{
    /* Hide the 'Pause' button, show the 'Play' button in the slider control */
    [self showPlayButton];
    seekToZeroBeforePlay = YES;
}

#pragma mark -
#pragma mark Timed metadata
#pragma mark -

- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata
{
    if ([(NSString *)[timedMetadata key] isEqualToString:AVMetadataID3MetadataKeyGeneralEncapsulatedObject])
    {
        if ([[timedMetadata value] isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *propertyList = (NSDictionary *)[timedMetadata value];
            
            /* Metadata payload could be the list of ads. */
            NSArray *newAdList = [propertyList objectForKey:@"ad-list"];
            if (newAdList != nil)
            {
                [self updateAdList:newAdList];
                NSLog(@"ad-list is %@", newAdList);
            }
            
            /* Or it might be an ad record. */
            NSString *adURL = [propertyList objectForKey:@"url"];
            if (adURL != nil)
            {
                if ([adURL isEqualToString:@""])
                {
                    /* Ad is not playing, so clear text. */
                    
                    [self enablePlayerButtons];
                    [self enableScrubber]; /* Enable seeking for main content. */
                    
                    NSLog(@"enabling seek at %g", CMTimeGetSeconds([[SinglePlayer sharedInstance].player currentTime]));
                }
                else
                {
                    /* Display text indicating that an Ad is now playing. */
                    
                    [self disablePlayerButtons];
                    [self disableScrubber]; 	/* Disable seeking for ad content. */
                    
                    NSLog(@"disabling seek at %g", CMTimeGetSeconds([[SinglePlayer sharedInstance].player currentTime]));
                }
            }
        }
    }
}

#pragma mark Ad list

/* Update current ad list, set slider to match current player item seekable time ranges */
- (void)updateAdList:(NSArray *)newAdList
{
    
}

#pragma mark -
#pragma mark Loading the Asset Keys Asynchronously

#pragma mark -
#pragma mark Error Handling - Preparing Assets for Playback Failed

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncScrubber];
    [self disableScrubber];
    [self disablePlayerButtons];
    
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

#pragma mark Prepare to play asset

- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{

    NSLog(@"prepare to play asset");
    /* Make sure that the value of each key has loaded successfully. */
    for (NSString *thisKey in requestedKeys)
    {
        NSError *error = nil;
        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
        if (keyStatus == AVKeyValueStatusFailed)
        {
            [self assetFailedToPrepareForPlayback:error];
            return;
        }
        /* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail
         out properly in the case of cancellation. */
    }
    
    /* Use the AVAsset playable property to detect whether the asset can be played. */
    if (!asset.playable)
    {
        /* Generate an error describing the failure. */
        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                   localizedDescription, NSLocalizedDescriptionKey,
                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                                   nil];
        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
        
        /* Display the error to the user. */
        [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
        
        return;
    }
    
    /* At this point we're ready to set up for playback of the asset. */
    
    [self initScrubberTimer];
    [self enableScrubber];
    [self enablePlayerButtons];
    
    /* Stop observing our prior AVPlayerItem, if we have one. */
    if (playerItem)
    {
        /* Remove existing player item key value observers and notifications. */
        
        [playerItem removeObserver:self forKeyPath:kStatusKey];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:playerItem];
    }
    
    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    /* Observe the player item "status" key to determine when it is ready to play. */
    [playerItem addObserver:self
                 forKeyPath:kStatusKey
                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                    context:MyStreamingMovieViewControllerPlayerItemStatusObserverContext];
    
    /* When the player item has played to its end time we'll toggle
     the movie controller Pause button to be the Play button */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
    //    seekToZeroBeforePlay = NO;
    
    /* Create new player, if we don't already have one. */
    if (![SinglePlayer sharedInstance].player)
    {
        /* Get a new AVPlayer initialized to play the specified player item. */
        [SinglePlayer sharedInstance].player =[AVPlayer playerWithPlayerItem:self.playerItem];
        
        /* Observe the AVPlayer "currentItem" property to find out when any
         AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
         occur.*/
        [[SinglePlayer sharedInstance].player addObserver:self
                                               forKeyPath:kCurrentItemKey
                                                  options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                  context:MyStreamingMovieViewControllerCurrentItemObservationContext];
        
        /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */
        [[SinglePlayer sharedInstance].player addObserver:self
                                               forKeyPath:kTimedMetadataKey
                                                  options:0
                                                  context:MyStreamingMovieViewControllerTimedMetadataObserverContext];
        
        /* Observe the AVPlayer "rate" property to update the scrubber control. */
        [[SinglePlayer sharedInstance].player addObserver:self
                                               forKeyPath:kRateKey
                                                  options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                                  context:MyStreamingMovieViewControllerRateObservationContext];
    }
    
    /* Make our new AVPlayerItem the AVPlayer's current item. */
    if ([SinglePlayer sharedInstance].player.currentItem != self.playerItem)
    {
        [[SinglePlayer sharedInstance].player replaceCurrentItemWithPlayerItem:self.playerItem];
        
        [self syncPlayPauseButtons];
    }
    
    [movieTimeControl setValue:0.0];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    /* AVPlayerItem "status" property value observer. */
    if (context == MyStreamingMovieViewControllerPlayerItemStatusObserverContext)
    {
        [self syncPlayPauseButtons];
        
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
                /* Indicates that the status of the player is not yet known because
                 it has not tried to load new media resources for playback */
            case AVPlayerStatusUnknown:
            {
                [self removePlayerTimeObserver];
                [self syncScrubber];
                
                [self disableScrubber];
                [self disablePlayerButtons];
            }
                break;
                
            case AVPlayerStatusReadyToPlay:
            {
                /* Once the AVPlayerItem becomes ready to play, i.e.
                 [playerItem status] == AVPlayerItemStatusReadyToPlay,
                 its duration can be fetched from the item. */
                
                playerLayerView.playerLayer.hidden = NO;
                [loadingIndicator stopAnimating];
                loadingIndicator.hidden = YES;
                [self toggleShowHideControls:YES];
                movieTimeControl.hidden = NO;
                
                [self enableScrubber];
                [self enablePlayerButtons];
                
                playerLayerView.playerLayer.backgroundColor = [[UIColor blackColor] CGColor];
                
                /* Set the AVPlayerLayer on the view to allow the AVPlayer object to display
                 its content. */
                [playerLayerView.playerLayer setPlayer:[SinglePlayer sharedInstance].player];
                
                [self initScrubberTimer];
                [self play:nil];
            }
                break;
                
            case AVPlayerStatusFailed:
            {
                AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
                [self assetFailedToPrepareForPlayback:thePlayerItem.error];
            }
                break;
        }
    }
    /* AVPlayer "rate" property value observer. */
    else if (context == MyStreamingMovieViewControllerRateObservationContext)
    {
        [self syncPlayPauseButtons];
    }
    /* AVPlayer "currentItem" property observer.
     Called when the AVPlayer replaceCurrentItemWithPlayerItem:
     replacement will/did occur. */
    else if (context == MyStreamingMovieViewControllerCurrentItemObservationContext)
    {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        /* New player item null? */
        if (newPlayerItem == (id)[NSNull null])
        {
            [self disablePlayerButtons];
            [self disableScrubber];
            
        }
        else /* Replacement of player currentItem has occurred */
        {
            /* Set the AVPlayer for which the player layer displays visual output. */
            [playerLayerView.playerLayer setPlayer:[SinglePlayer sharedInstance].player];
            
            /* Specifies that the player should preserve the video’s aspect ratio and
             fit the video within the layer’s bounds. */
            [playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
            
            [self syncPlayPauseButtons];
        }
    }
    /* Observe the AVPlayer "currentItem.timedMetadata" property to parse the media stream
     timed metadata. */
    else if (context == MyStreamingMovieViewControllerTimedMetadataObserverContext)
    {
        NSArray* array = [[[SinglePlayer sharedInstance].player currentItem] timedMetadata];
        for (AVMetadataItem *metadataItem in array)
        {
            [self handleTimedMetadata:metadataItem];
        }
    }
    else
    {
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
    }
    
    return;
}


#pragma mark Play, Stop Buttons

/* Show the stop button in the movie player controller. */
-(void)showStopButton
{
    
    stopBtn.hidden = NO;
    playBtn.hidden = YES;
}

/* Show the play button in the movie player controller. */
-(void)showPlayButton
{
    
    stopBtn.hidden = YES;
    playBtn.hidden = NO;
}

/* If the media is playing, show the stop button; otherwise, show the play button. */
- (void)syncPlayPauseButtons
{
    if ([self isPlaying])
    {
        [self showStopButton];
    }
    else
    {
        [self showPlayButton];
    }
}

-(void)enablePlayerButtons
{
    playBtn.enabled = YES;
    stopBtn.enabled = YES;
}

-(void)disablePlayerButtons
{
    playBtn.enabled = NO;
    stopBtn.enabled = NO;
}

#pragma mark Scrubber control

/* Set the scrubber based on the player current time. */
- (void)syncScrubber
{
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        movieTimeControl.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration) && (duration > 0))
    {
        NSString *current = [NSString stringWithFormat:@"%d:%02d", (int)CMTimeGetSeconds([SinglePlayer sharedInstance].player.currentTime )/ 60, (int)CMTimeGetSeconds([SinglePlayer sharedInstance].player.currentTime) % 60, nil];
        NSString *dur = [NSString stringWithFormat:@"-%d:%02d", (int)((int)(CMTimeGetSeconds([SinglePlayer sharedInstance].player.currentItem.asset.duration) - CMTimeGetSeconds([SinglePlayer sharedInstance].player.currentTime))) / 60, (int)((int)(CMTimeGetSeconds([SinglePlayer sharedInstance].player.currentItem.asset.duration) - CMTimeGetSeconds([SinglePlayer sharedInstance].player.currentTime))) % 60, nil];
        remainTime.text = dur;
        currentTime.text = current;
        float minValue = [movieTimeControl minimumValue];
        float maxValue = [movieTimeControl maximumValue];
        double time = CMTimeGetSeconds([[SinglePlayer sharedInstance].player currentTime]);
        
        [movieTimeControl setValue:(maxValue - minValue) * time / duration + minValue];
    }
}


#pragma mark Button Action Methods

- (IBAction)play:(id)sender
{
    /* If we are at the end of the movie, we must seek to the beginning first
     before starting playback. */
    if (YES == seekToZeroBeforePlay)
    {
        seekToZeroBeforePlay = NO;
        [[SinglePlayer sharedInstance].player seekToTime:kCMTimeZero];
    }
    
    [[SinglePlayer sharedInstance].player play];
    
    [self showStopButton];
}

- (IBAction)pause:(id)sender
{
    [[SinglePlayer sharedInstance].player pause];
    
    [self showPlayButton];
}


#pragma mark New Player

/* Requests invocation of a given block during media playback to update the
 movie scrubber control. */
-(void)initScrubberTimer
{
    double interval = .1f;
    
    CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration))
    {
        return;
    }
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration))
    {
        CGFloat width = CGRectGetWidth([movieTimeControl bounds]);
        interval = 0.5f * duration / width;
    }
    
    __unsafe_unretained typeof(self) weakSelf = self;
    /* Update the scrubber during normal playback. */
    timeObserver = [[SinglePlayer sharedInstance].player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)queue:NULL usingBlock: ^(CMTime time) {
            [weakSelf syncScrubber];
    }];
}


/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
    if (timeObserver)
    {
        [[SinglePlayer sharedInstance].player removeTimeObserver:timeObserver];
        timeObserver = nil;
    }
}

-(void)removePlayerObserver{
    
    [[SinglePlayer sharedInstance].player removeObserver:self forKeyPath:kRateKey];
    [[SinglePlayer sharedInstance].player removeObserver:self forKeyPath:kTimedMetadataKey];
    [[SinglePlayer sharedInstance].player removeObserver:self forKeyPath:kCurrentItemKey];
    [[SinglePlayer sharedInstance].player.currentItem removeObserver:self forKeyPath:kStatusKey];
}

/* The user is dragging the movie controller thumb to scrub through the movie. */
- (IBAction)beginScrubbing:(id)sender
{
    restoreAfterScrubbingRate = [[SinglePlayer sharedInstance].player rate];
    [[SinglePlayer sharedInstance].player setRate:0.f];
    
    /* Remove previous timer. */
    [self removePlayerTimeObserver];
}

/* The user has released the movie thumb control to stop scrubbing through the movie. */
- (IBAction)endScrubbing:(id)sender
{
    if (!timeObserver)
    {
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration))
        {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            CGFloat width = CGRectGetWidth([movieTimeControl bounds]);
            double tolerance = 0.5f * duration / width;
            __unsafe_unretained typeof(self) weakSelf = self;
            timeObserver = [[SinglePlayer sharedInstance].player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(tolerance, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:
                            ^(CMTime time)
                            {
                                [weakSelf syncScrubber];
                            }];
        }
    }
    
    if (restoreAfterScrubbingRate)
    {
        [[SinglePlayer sharedInstance].player setRate:restoreAfterScrubbingRate];
        restoreAfterScrubbingRate = 0.f;
    }
}

/* Set the player current time to match the scrubber position. */
- (IBAction)scrub:(id)sender
{
    if ([sender isKindOfClass:[UISlider class]])
    {
        UISlider* slider = sender;
        
        CMTime playerDuration = [self playerItemDuration];
        if (CMTIME_IS_INVALID(playerDuration)) {
            return;
        }
        
        double duration = CMTimeGetSeconds(playerDuration);
        if (isfinite(duration))
        {
            float minValue = [slider minimumValue];
            float maxValue = [slider maximumValue];
            float value = [slider value];
            
            double time = duration * (value - minValue) / (maxValue - minValue);
            
            [[SinglePlayer sharedInstance].player seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC)];
        }
    }
}

- (BOOL)isScrubbing
{
    return restoreAfterScrubbingRate != 0.f;
}

-(void)enableScrubber
{
    movieTimeControl.enabled = YES;
}

-(void)disableScrubber
{
    movieTimeControl.enabled = NO;
}

/* Prevent the slider from seeking during Ad playback. */
- (void)sliderSyncToPlayerSeekableTimeRanges
{
    NSArray *seekableTimeRanges = [[[SinglePlayer sharedInstance].player currentItem] seekableTimeRanges];
    if ([seekableTimeRanges count] > 0)
    {
        NSValue *range = [seekableTimeRanges objectAtIndex:0];
        CMTimeRange timeRange = [range CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        
        /* Set the minimum and maximum values of the time slider to match the seekable time range. */
        movieTimeControl.minimumValue = startSeconds;
        movieTimeControl.maximumValue = startSeconds + durationSeconds;
    }
}

@end
