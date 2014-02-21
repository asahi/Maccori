//
//  MCRPhotoServiceConstants.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoPickerControllerConstants.h"
@interface MCRPhotoServiceConstants : NSObject
@end

UIKIT_EXTERN NSString *NSUserDefaultsUniqueKey(NSUInteger type, NSString *key);

UIKIT_EXTERN NSURL *baseURLForService(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *tagsResourceKeyPathForService(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *tagSearchUrlPathForService(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *photosResourceKeyPathForService(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *photoSearchUrlPathForService(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *keyForAPIConsumerKey(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *keyForSearchTerm(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *keyForSearchTag(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *keyForSearchResultPerPage(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *keyForSearchTagContent(MCRPhotoPickerControllerService service);

UIKIT_EXTERN NSString *keyPathForObjectName(MCRPhotoPickerControllerService service, NSString *objectName);

