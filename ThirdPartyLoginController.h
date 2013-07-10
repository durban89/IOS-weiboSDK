//
//  ThirdPartyLoginController.h
//  xunYi7
//
//  Created by david on 13-7-10.
//  Copyright (c) 2013年 david. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SinaWeiboRequest.h"
#import "SinaWeibo.h"
#import "SinaWeiboConstants.h"
#import <QuartzCore/QuartzCore.h>

#define kAppKey             @"xxxxxxxxxx"
#define kAppSecret          @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
#define kAppRedirectURI     @"https://api.weibo.com/oauth2/default.html"

#ifndef kAppKey
#error
#endif

#ifndef kAppSecret
#error
#endif

#ifndef kAppRedirectURI
#error
#endif

@interface ThirdPartyLoginController : UIViewController<UIWebViewDelegate, SinaWeiboDelegate, SinaWeiboRequestDelegate>


@property (strong, nonatomic) IBOutlet UIWebView *weiboLoginWeb;
@property (retain, nonatomic) UIActivityIndicatorView *indicatorView;
@property (retain, nonatomic) NSDictionary *authParams;
@property (retain, nonatomic) NSString *appRedirectURI;
@property (retain, nonatomic) SinaWeiboRequest *sinaWeiboRequest;

@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSString *accessToken;
@property (nonatomic, retain) NSDate *expirationDate;
@property (nonatomic, retain) NSString *refreshToken;

@property (nonatomic) UIInterfaceOrientation previousOrientation;

@end
