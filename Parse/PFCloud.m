/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCloud.h"

#import "BFTask+Private.h"
#import "PFCloudCodeController.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@implementation PFCloud

///--------------------------------------
#pragma mark - Public
///--------------------------------------

+ (void)useWADapiOrNot:(NSString *)function{
    //Define functions which will be redirected to api2.wineadvisor.com
    NSArray *webhookFunctions = [NSArray arrayWithObjects:
                                 @"getTrending",
                                 @"follow",
                                 @"unFollow",
                                 @"getAds",
                                 @"likeWine",
                                 @"unlikeWine",
                                 @"getBadgeView",
                                 @"getPersonalTimeline",
                                 @"getFollowingTimeline",
                                 @"getFollowingTimeline",
                                 @"getFollowing",
                                 @"getFollowers",
                                 @"getCellar",
                                 @"getListing",
                                 nil];
    //Enable or disable redirection
    if ([webhookFunctions containsObject:function]) {
        [PFInternalUtils setParseServer:@"https://api2.wineadvisor.com"];
    } else {
        [PFInternalUtils setParseServer:kPFParseServer];
    }
    NSString *url = [PFInternalUtils parseServerURLString];
    NSLog([NSString stringWithFormat:@"%@/1/functions/%@", url, function]);
}

+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters {
    return [self callFunction:function withParameters:parameters error:nil];
}

+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters error:(NSError **)error {
    [self useWADapiOrNot:function];
    return [[self callFunctionInBackground:function withParameters:parameters] waitForResult:error];
}

+ (BFTask *)callFunctionInBackground:(NSString *)functionName withParameters:(NSDictionary *)parameters {
    [self useWADapiOrNot:functionName];
    return [[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFCloudCodeController *controller = [Parse _currentManager].coreManager.cloudCodeController;
        return [controller callCloudCodeFunctionAsync:functionName
                                       withParameters:parameters
                                         sessionToken:sessionToken];
    }];
}

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(NSDictionary *)parameters
                          target:(id)target
                        selector:(SEL)selector {
    [self useWADapiOrNot:function];
    [self callFunctionInBackground:function withParameters:parameters block:^(id results, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:results object:error];
    }];
}

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(NSDictionary *)parameters
                           block:(PFIdResultBlock)block {
    [self useWADapiOrNot:function];
    [[self callFunctionInBackground:function withParameters:parameters] thenCallBackOnMainThreadAsync:block];
}


@end
