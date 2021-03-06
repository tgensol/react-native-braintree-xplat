//
//  RCTBraintree.h
//  RCTBraintree
//
//  Created by Rickard Ekman on 18/06/16.
//  Copyright © 2016 Rickard Ekman. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTUtils.h>
#import <React/RCTConvert.h>

#import "BraintreePaymentFlow.h"
#import "BraintreeCore.h"
#import "BraintreePayPal.h"
#import "BraintreeCard.h"
#import "BTDataCollector.h"
#import "PPDataCollector.h"

@interface RCTBraintree : UIViewController <RCTBridgeModule, BTViewControllerPresentingDelegate>
@property (nonatomic, strong, readwrite) BTPaymentFlowDriver *paymentFlowDriver;
@property (nonatomic, strong) BTAPIClient *braintreeClient;
// @property (nonatomic, strong, readwrite) BTThreeDSecureDriver *threeDSecure;
@property (nonatomic, strong) UIViewController *reactRoot;
@property (nonatomic, strong) BTDataCollector *dataCollector;

@property (nonatomic, strong) RCTResponseSenderBlock callback;
// @property (nonatomic, strong) NSDictionary *threeDSecureOptions;

+ (instancetype)sharedInstance;
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *) options;
@end
