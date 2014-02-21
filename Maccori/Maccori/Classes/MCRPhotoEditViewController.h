//
//  MCRPhotoEditViewController.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoPickerControllerConstants.h"

@class MCRPhotoMetadata;

@interface MCRPhotoEditViewController : UIViewController
@property (nonatomic, readonly) MCRPhotoEditViewControllerCropMode cropMode;
@property (nonatomic) CGSize cropSize;

- (instancetype)initWithPhotoMetadata:(MCRPhotoMetadata *)metadata cropMode:(MCRPhotoEditViewControllerCropMode)mode;

- (instancetype)initWithImage:(UIImage *)image cropMode:(MCRPhotoEditViewControllerCropMode)mode;

+ (void)editImage:(UIImage *)image cropMode:(MCRPhotoEditViewControllerCropMode)mode inNavigationController:(UINavigationController *)controller;

+ (void)didFinishPickingOriginalImage:(UIImage *)originalImage
                          editedImage:(UIImage *)editedImage
                             cropRect:(CGRect)cropRect
                             cropMode:(MCRPhotoEditViewControllerCropMode)cropMode
                        photoMetadata:(MCRPhotoMetadata *)metadata;

@end
