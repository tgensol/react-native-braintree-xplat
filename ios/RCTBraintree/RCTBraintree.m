//
//  RCTBraintree.m
//  RCTBraintree
//
//  Created by Rickard Ekman on 18/06/16.
//  Copyright © 2016 Rickard Ekman. All rights reserved.
//

#import "RCTBraintree.h"

@implementation RCTBraintree {
    bool runCallback;
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

static NSString *URLScheme;

+ (instancetype)sharedInstance {
    static RCTBraintree *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[RCTBraintree alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    if ((self = [super init])) {
        self.dataCollector = [[BTDataCollector alloc]
                              initWithEnvironment:BTDataCollectorEnvironmentProduction];
    }
    return self;
}

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(setupWithURLScheme:(NSString *)serverUrl urlscheme:(NSString*)urlscheme callback:(RCTResponseSenderBlock)callback)
{
    URLScheme = urlscheme;
    [BTAppSwitch setReturnURLScheme:urlscheme];
    
    NSURL *clientTokenURL = [NSURL URLWithString:serverUrl];
    NSMutableURLRequest *clientTokenRequest = [NSMutableURLRequest requestWithURL:clientTokenURL];
    [clientTokenRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:clientTokenRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSString *clientToken = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
        
        if (self.braintreeClient == nil) {
            callback(@[@false]);
        }
        else {
            callback(@[@true]);
        }
    }] resume];
}


RCT_EXPORT_METHOD(setup:(NSString *)clientToken callback:(RCTResponseSenderBlock)callback)
{
    self.braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    if (self.braintreeClient == nil) {
        callback(@[@false]);
    }
    else {
        callback(@[@true]);
    }
}

RCT_EXPORT_METHOD(showPayPalViewController:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithAPIClient:self.braintreeClient];
        payPalDriver.viewControllerPresentingDelegate = self;
        
        [payPalDriver authorizeAccountWithCompletion:^(BTPayPalAccountNonce *tokenizedPayPalAccount, NSError *error) {
            NSMutableArray *args = @[[NSNull null]];
            if ( error == nil && tokenizedPayPalAccount != nil ) {
                args = [@[[NSNull null], tokenizedPayPalAccount.nonce, tokenizedPayPalAccount.email, tokenizedPayPalAccount.firstName, tokenizedPayPalAccount.lastName] mutableCopy];
                
                if (tokenizedPayPalAccount.phone != nil) {
                    [args addObject:tokenizedPayPalAccount.phone];
                }
            } else if ( error != nil ) {
                args = @[error.description, [NSNull null]];
            }
            
            callback(args);
        }];
    });
}


RCT_EXPORT_METHOD(check3DSecure: (NSDictionary *)parameters callback: (RCTResponseSenderBlock)callback)
{
    
    BTThreeDSecureRequest *threeDSecureRequest = [[BTThreeDSecureRequest alloc] init];
    threeDSecureRequest.amount = [NSDecimalNumber decimalNumberWithString: parameters[@"amount"]];
    threeDSecureRequest.nonce =  parameters[@"nonce"];
    
    threeDSecureRequest.email = parameters[@"email"];
    //                          threeDSecureRequest.versionRequested = BTThreeDSecureVersion2;
    
    BTThreeDSecurePostalAddress *address = [BTThreeDSecurePostalAddress new];
    address.givenName =  parameters[@"firstname"]; // ASCII-printable characters required, else will throw a validation error
    address.surname = parameters[@"lastname"]; // ASCII-printable characters required, else will throw a validation error
    address.phoneNumber = parameters[@"phoneNumber"];
    address.streetAddress = parameters[@"streetAddress"];
    address.locality = parameters[@"locality"];
    address.region = parameters[@"region"];
    address.postalCode = parameters[@"postalCode"];
    //                          address.countryCodeAlpha2 = @"US";
    
    //                          BTThreeDSecurePostalAddress *address = [BTThreeDSecurePostalAddress new];
    //                          address.givenName = @"Jill"; // ASCII-printable characters required, else will throw a validation error
    //                          address.surname = @"Doe"; // ASCII-printable characters required, else will throw a validation error
    //                          address.phoneNumber = @"5551234567";
    //                          address.streetAddress = @"555 Smith St";
    //                          address.extendedAddress = @"#2";
    //                          address.locality = @"Chicago";
    //                          address.region = @"IL";
    //                          address.postalCode = @"12345";
    //                          address.countryCodeAlpha2 = @"US";
    
    threeDSecureRequest.billingAddress = address;
    // Optional additional information.
    // For best results, provide as many of these elements as possible.
    BTThreeDSecureAdditionalInformation *additionalInformation = [BTThreeDSecureAdditionalInformation new];
    additionalInformation.shippingAddress = address;
    threeDSecureRequest.additionalInformation = additionalInformation;
    
    //
    self.paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:self.braintreeClient];
    self.paymentFlowDriver.viewControllerPresentingDelegate = self;
    
    
    [self.paymentFlowDriver startPaymentFlow:threeDSecureRequest completion:^(BTPaymentFlowResult * _Nonnull result, NSError * _Nonnull error) {
        NSArray *args = @[];
        if (error) {
            NSLog(@"Finally error %@", error.description);
            args = @[error.localizedDescription, [NSNull null]];
            // Handle error
        } else if (result) {
            NSLog(@"Finally %@", result);
            BTThreeDSecureResult *threeDSecureResult = (BTThreeDSecureResult *)result;
            
            if (threeDSecureResult.tokenizedCard.threeDSecureInfo.liabilityShiftPossible) {
                if (threeDSecureResult.tokenizedCard.threeDSecureInfo.liabilityShifted) {
                    args = @[[NSNull null], @true];
                } else {
                    // 3D Secure authentication failed
                    //   args = @[serialisationErr.description, [NSNull null]];
                    args = @[@"failed", [NSNull null]];
                }
            }else{
                args = @[[NSNull null], @true];
            }
        }else{
            // 3D Secure authentication was not possible
            args = @[[NSNull null], @true];
        }
        callback(args);
    }];
    
}


RCT_EXPORT_METHOD(getCardNonce: (NSDictionary *)parameters callback: (RCTResponseSenderBlock)callback)
{
    BTCardClient *cardClient = [[BTCardClient alloc] initWithAPIClient: self.braintreeClient];
    BTCard *card =  [[BTCard alloc] initWithNumber:parameters[@"number"]
                                   expirationMonth:parameters[@"expirationMonth"]
                                    expirationYear:parameters[@"expirationYear"]
                                               cvv:parameters[@"cvv"]];
    card.shouldValidate = NO;
    [cardClient tokenizeCard:card
                  completion:^(BTCardNonce *tokenizedCard, NSError *error) {
                      if ( error == nil ) {
                          if(parameters[@"amount"] == nil){
                               NSArray *args = @[];
                               args = @[[NSNull null], tokenizedCard.nonce];
                               callback(args);
                          }else{
                          BTThreeDSecureRequest *threeDSecureRequest = [[BTThreeDSecureRequest alloc] init];
                          threeDSecureRequest.amount = [NSDecimalNumber decimalNumberWithString: parameters[@"amount"]];
                          threeDSecureRequest.nonce = tokenizedCard.nonce;
                          
                          threeDSecureRequest.email = parameters[@"email"];
                          //                          threeDSecureRequest.versionRequested = BTThreeDSecureVersion2;
                          
                          BTThreeDSecurePostalAddress *address = [BTThreeDSecurePostalAddress new];
                          address.givenName =  parameters[@"firstname"]; // ASCII-printable characters required, else will throw a validation error
                          address.surname = parameters[@"lastname"]; // ASCII-printable characters required, else will throw a validation error
                          address.phoneNumber = parameters[@"phoneNumber"];
                          address.streetAddress = parameters[@"streetAddress"];
                          address.locality = parameters[@"locality"];
                          address.region = parameters[@"region"];
                          address.postalCode = parameters[@"postalCode"];
                          //                          address.countryCodeAlpha2 = @"US";
                          
                          //                          BTThreeDSecurePostalAddress *address = [BTThreeDSecurePostalAddress new];
                          //                          address.givenName = @"Jill"; // ASCII-printable characters required, else will throw a validation error
                          //                          address.surname = @"Doe"; // ASCII-printable characters required, else will throw a validation error
                          //                          address.phoneNumber = @"5551234567";
                          //                          address.streetAddress = @"555 Smith St";
                          //                          address.extendedAddress = @"#2";
                          //                          address.locality = @"Chicago";
                          //                          address.region = @"IL";
                          //                          address.postalCode = @"12345";
                          //                          address.countryCodeAlpha2 = @"US";
                          
                          threeDSecureRequest.billingAddress = address;
                          // Optional additional information.
                          // For best results, provide as many of these elements as possible.
                          BTThreeDSecureAdditionalInformation *additionalInformation = [BTThreeDSecureAdditionalInformation new];
                          additionalInformation.shippingAddress = address;
                          threeDSecureRequest.additionalInformation = additionalInformation;
                          
                          //
                          self.paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:self.braintreeClient];
                          self.paymentFlowDriver.viewControllerPresentingDelegate = self;
                          
                          
                          [self.paymentFlowDriver startPaymentFlow:threeDSecureRequest completion:^(BTPaymentFlowResult * _Nonnull result, NSError * _Nonnull error) {
                              NSArray *args = @[];
                              if (error) {
                                  NSLog(@"Finally error %@", error.description);
                                  args = @[error.localizedDescription, [NSNull null]];
                                  // Handle error
                              } else if (result) {
                                  NSLog(@"Finally %@", result);
                                  BTThreeDSecureResult *threeDSecureResult = (BTThreeDSecureResult *)result;
                                  
                                  if (threeDSecureResult.tokenizedCard.threeDSecureInfo.liabilityShiftPossible) {
                                      if (threeDSecureResult.tokenizedCard.threeDSecureInfo.liabilityShifted) {
                                          args = @[[NSNull null], threeDSecureResult.tokenizedCard.nonce];
                                      } else {
                                          // 3D Secure authentication failed
                                          //   args = @[serialisationErr.description, [NSNull null]];
                                          args = @[@"failed", [NSNull null]];
                                      }
                                  }else{
                                      args = @[[NSNull null], threeDSecureResult.tokenizedCard.nonce];
                                  }
                              }else{
                                  // 3D Secure authentication was not possible
                                  args = @[[NSNull null], tokenizedCard.nonce];
                              }
                              callback(args);
                          }];
                          }
                          
                      } else {
                          
                          NSArray *args = @[];
                          
                          
                          
                          NSMutableDictionary *userInfo = [error.userInfo mutableCopy];
                          
                          [userInfo removeObjectForKey:@"com.braintreepayments.BTHTTPJSONResponseBodyKey"];
                          [userInfo removeObjectForKey:@"com.braintreepayments.BTHTTPURLResponseKey"];
                          NSError *serialisationErr;
                          NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo
                                                                             options:NSJSONWritingPrettyPrinted
                                                                               error:&serialisationErr];
                          
                          if (! jsonData) {
                              args = @[serialisationErr.description, [NSNull null]];
                          } else {
                              NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                              args = @[jsonString, [NSNull null]];
                          }
                          callback(args);
                      }
                      
                      
                  }];
}

RCT_EXPORT_METHOD(getDeviceData:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"%@", options);
        
        NSError *error = nil;
        NSString *deviceData = nil;
        NSString *environment = options[@"environment"];
        NSString *dataSelector = options[@"dataCollector"];
        
        //Initialize the data collector and specify environment
        if([environment isEqualToString: @"development"]){
            self.dataCollector = [[BTDataCollector alloc]
                                  initWithEnvironment:BTDataCollectorEnvironmentDevelopment];
        } else if([environment isEqualToString: @"qa"]){
            self.dataCollector = [[BTDataCollector alloc]
                                  initWithEnvironment:BTDataCollectorEnvironmentQA];
        } else if([environment isEqualToString: @"sandbox"]){
            self.dataCollector = [[BTDataCollector alloc]
                                  initWithEnvironment:BTDataCollectorEnvironmentSandbox];
        }
        
        //Data collection methods
        if ([dataSelector isEqualToString: @"card"]){
            deviceData = [self.dataCollector collectCardFraudData];
        } else if ([dataSelector isEqualToString: @"both"]){
            deviceData = [self.dataCollector collectFraudData];
        } else if ([dataSelector isEqualToString: @"paypal"]){
            deviceData = [PPDataCollector collectPayPalDeviceData];
        } else {
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"Invalid data collector" forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"RCTBraintree" code:255 userInfo:details];
            NSLog (@"Invalid data collector. Use one of: card, paypal or both");
        }
        
        NSArray *args = @[];
        if ( error == nil ) {
            args = @[[NSNull null], deviceData];
        } else {
            args = @[error.description, [NSNull null]];
        }
        
        callback(args);
    });
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([url.scheme localizedCaseInsensitiveCompare:URLScheme] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url sourceApplication:sourceApplication];
    }
    return NO;
}

#pragma mark - BTViewControllerPresentingDelegate

- (void)paymentDriver:(id)paymentDriver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self.reactRoot presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(id)paymentDriver requestsDismissalOfViewController:(UIViewController *)viewController {
    if (!self.reactRoot.isBeingDismissed) {
        [self.reactRoot.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

// #pragma mark - BTDropInViewControllerDelegate

- (void)userDidCancelPayment {
    [self.reactRoot dismissViewControllerAnimated:YES completion:nil];
    runCallback = FALSE;
    self.callback(@[@"USER_CANCELLATION", [NSNull null]]);
}

- (UIViewController*)reactRoot {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (root.presentedViewController) {
        root = root.presentedViewController;
    }
    
    return root;
}

@end
