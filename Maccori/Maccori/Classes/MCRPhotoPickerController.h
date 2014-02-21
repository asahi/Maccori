//
//  MCRPhotoPickerController.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCRPhotoEditViewController.h"

@protocol MCRPhotoPickerControllerDelegate;

@interface MCRPhotoPickerController : UINavigationController

@property (nonatomic, assign) id <UINavigationControllerDelegate, MCRPhotoPickerControllerDelegate> delegate;
@property (nonatomic) MCRPhotoPickerControllerService supportedServices;
@property (nonatomic) BOOL allowsEditing;
@property (nonatomic, copy) NSString *initialSearchTerm;
@property (nonatomic) MCRPhotoEditViewControllerCropMode editingMode;

- (instancetype)initWithEditableImage:(UIImage *)image;
+ (void)registerService:(MCRPhotoPickerControllerService)service
            consumerKey:(NSString *)key
         consumerSecret:(NSString *)secret;
@end

@protocol MCRPhotoPickerControllerDelegate <NSObject>
@required
- (void)photoPickerController:(MCRPhotoPickerController *)picker didFinishPickingPhotoWithInfo:(NSDictionary *)userInfo;
- (void)photoPickerControllerDidCancel:(MCRPhotoPickerController *)picker;
@end
