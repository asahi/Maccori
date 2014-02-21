//
//  MCRPhotoServiceFactory.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoPickerControllerConstants.h"
#import "MCRPhotoServiceClientProtocol.h"

@interface MCRPhotoServiceFactory : NSObject

+ (instancetype)defaultFactory;
- (id<MCRPhotoServiceClientProtocol>)clientForService:(MCRPhotoPickerControllerService)service;
+ (void)setConsumerKey:(NSString *)key consumerSecret:(NSString *)secret
               service:(MCRPhotoPickerControllerService)service;
- (void)reset;

@end
