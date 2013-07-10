//
//  ThirdPartyLoginController.m
//  xunYi7
//
//  Created by david on 13-7-10.
//  Copyright (c) 2013年 david. All rights reserved.
//

#import "ThirdPartyLoginController.h"
#import "UserCenter.h"


@interface ThirdPartyLoginController ()

@end

@implementation ThirdPartyLoginController

@synthesize weiboLoginWeb;
@synthesize indicatorView;
@synthesize authParams;
@synthesize appRedirectURI;
@synthesize sinaWeiboRequest;

@synthesize userID;
@synthesize accessToken;
@synthesize expirationDate;
@synthesize refreshToken;

@synthesize previousOrientation;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"微博登录";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    weiboLoginWeb.delegate = self;
    
    indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                     UIActivityIndicatorViewStyleGray];
    indicatorView.autoresizingMask =
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
    | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.view addSubview:indicatorView];
}

-(void) viewWillAppear:(BOOL)animated{
    self.authParams = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                            kAppKey, @"client_id",
                            @"code", @"response_type",
                            kAppRedirectURI, @"redirect_uri",
                            @"mobile", @"display", nil];
    self.appRedirectURI = kAppRedirectURI;
    self.sinaWeiboRequest = [[SinaWeiboRequest alloc] init];
    sinaWeiboRequest.delegate = self;
    
    [self show];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SinaWeiboRequestDelegate Methods
- (void)request:(SinaWeiboRequest *)request didReceiveResponse:(NSURLResponse *)response{
    NSLog(@"response = %@",response);

}
- (void)request:(SinaWeiboRequest *)request didReceiveRawData:(NSData *)data{
    NSLog(@"data = %@",data);

}
- (void)request:(SinaWeiboRequest *)request didFailWithError:(NSError *)error{
    NSLog(@"error = %@",error);
}

- (void)request:(SinaWeiboRequest *)request didFinishLoadingWithResult:(id)result{
    NSLog(@"result = %@",result);
    if([UserCenter saveWeiboAuth:result]){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

#pragma mark - Activity Indicator
- (void)showIndicator
{
    [indicatorView sizeToFit];
    [indicatorView startAnimating];
    indicatorView.center = weiboLoginWeb.center;
}

- (void)hideIndicator
{
    [indicatorView stopAnimating];
}

#pragma mark - Show / Hide
- (void)load{
    NSString *authPagePath = [SinaWeiboRequest serializeURL:kSinaWeiboWebAuthURL
                                                     params:authParams httpMethod:@"GET"];
    [weiboLoginWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:authPagePath]]];
}

- (void)show
{
    [self load];
    [self showIndicator];
    [self addObservers];
}

- (void)hide
{
    [self removeObservers];
    
    [weiboLoginWeb stopLoading];
    
}

- (void)cancel
{
    [self hide];
}

#pragma mark - UIDeviceOrientationDidChangeNotification Methods
- (void)deviceOrientationDidChange:(id)object
{
  
}


#pragma mark Obeservers
- (void)addObservers
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}

- (void)removeObservers{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}


#pragma mark - UIWebView Delegate

- (void)webViewDidFinishLoad:(UIWebView *)aWebView{
	[self hideIndicator];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    [self hideIndicator];
}


- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    NSString *url = request.URL.absoluteString;
    
    NSString *siteRedirectURI = [NSString stringWithFormat:@"%@%@", kSinaWeiboSDKOAuth2APIDomain, appRedirectURI];
    
    if ([url hasPrefix:appRedirectURI] || [url hasPrefix:siteRedirectURI]){
        NSString *error_code = [SinaWeiboRequest getParamValueFromUrl:url paramName:@"error_code"];
        
        if (error_code){
            NSString *error = [SinaWeiboRequest getParamValueFromUrl:url paramName:@"error"];
            NSString *error_uri = [SinaWeiboRequest getParamValueFromUrl:url paramName:@"error_uri"];
            NSString *error_description = [SinaWeiboRequest getParamValueFromUrl:url paramName:@"error_description"];
            
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                       error, @"error",
                                       error_uri, @"error_uri",
                                       error_code, @"error_code",
                                       error_description, @"error_description", nil];
            NSLog(@"errorInfo = %@",errorInfo);
            
            [self hide];
            
        }else{
            NSString *code = [SinaWeiboRequest getParamValueFromUrl:url paramName:@"code"];
            if (code){
                [self hide];
                
                NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                        kAppKey, @"client_id",
                                        kAppSecret, @"client_secret",
                                        @"authorization_code", @"grant_type",
                                        self.appRedirectURI, @"redirect_uri",
                                        code, @"code", nil];
                
                
                [sinaWeiboRequest disconnect];
                sinaWeiboRequest = nil;
                
                self.sinaWeiboRequest = [SinaWeiboRequest requestWithURL:kSinaWeiboWebAccessTokenURL
                                                 httpMethod:@"POST"
                                                     params:params
                                                   delegate:self];
                
                
                [sinaWeiboRequest connect];
            }
        }
        
        return NO;
    }
    
    return YES;
}

/**
 * @description 清空认证信息
 */
- (void)removeAuthData{
//    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    NSArray* sinaweiboCookies = [cookies cookiesForURL:
//                                 [NSURL URLWithString:@"https://open.weibo.cn"]];
//    
//    for (NSHTTPCookie* cookie in sinaweiboCookies)
//    {
//        [cookies deleteCookie:cookie];
//    }
}
/**
 * @description 判断是否登录
 * @return YES为已登录；NO为未登录
 */
- (BOOL)isLoggedIn
{
    return userID && accessToken && expirationDate;
}

/**
 * @description 判断登录是否过期
 * @return YES为已过期；NO为未为期
 */
- (BOOL)isAuthorizeExpired
{
    NSDate *now = [NSDate date];
    return ([now compare:expirationDate] == NSOrderedDescending);
}


/**
 * @description 判断登录是否有效，当已登录并且登录未过期时为有效状态
 * @return YES为有效；NO为无效
 */
- (BOOL)isAuthValid
{
    return ([self isLoggedIn] && ![self isAuthorizeExpired]);
}
@end
