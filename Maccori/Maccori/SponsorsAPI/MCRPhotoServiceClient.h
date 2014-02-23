//
//  MCRPhotoServiceClient.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import <AFNetworking/AFHTTPClient.h>
#import "MCRPhotoPickerControllerConstants.h"
#import "MCRPhotoServiceClientProtocol.h"

UIKIT_EXTERN NSString *const MCRPhotoServiceClientConsumerKey;
UIKIT_EXTERN NSString *const MCRPhotoServiceClientConsumerSecret;

/*
 * The HTTP service client used to interact with multiple RESTful APIs for photo search services.
 */
@interface MCRPhotoServiceClient : AFHTTPClient <MCRPhotoServiceClientProtocol>

- (instancetype)initWithService:(MCRPhotoPickerControllerService)service;
- (void)getObject:(NSString *)objectName path:(NSString *)path params:(NSDictionary *)params completion:(MCRHTTPSearchRequestCompletion)completion;
- (NSData *)processData:(NSData *)data;
@end
