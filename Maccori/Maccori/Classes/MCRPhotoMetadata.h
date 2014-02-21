//
//  MCRPhotoMetadata.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCRPhotoPickerControllerConstants.h"

@interface MCRPhotoMetadata : NSObject

@property (nonatomic, copy) id Id;
@property (nonatomic, copy) NSURL *thumbURL;
@property (nonatomic, copy) NSURL *sourceURL;
@property (nonatomic, copy) NSURL *detailURL;
@property (nonatomic, copy) NSString *authorName;
@property (nonatomic, copy) NSString *authorUsername;
@property (nonatomic, copy) NSURL *authorProfileURL;
@property (nonatomic, copy) NSString *serviceName;

+ (NSString *)name;
+ (instancetype)photoMetadataFromService:(MCRPhotoPickerControllerService)service;
+ (NSArray *)photoMetadataListFromService:(MCRPhotoPickerControllerService)service withResponse:(NSArray *)reponse;

@end
