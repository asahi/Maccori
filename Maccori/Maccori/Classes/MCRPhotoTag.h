//
//  MCRPhotoTag.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoPickerControllerConstants.h"

@interface MCRPhotoTag : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *serviceName;

+ (NSString *)name;
+ (instancetype)photoTagFromService:(MCRPhotoPickerControllerService)service;
+ (NSArray *)photoTagListFromService:(MCRPhotoPickerControllerService)service withResponse:(NSArray *)reponse;

@end
