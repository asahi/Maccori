//
//  MCRPhotoPickerControllerConstants.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

UIKIT_EXTERN NSString *const MCRPhotoPickerControllerCropMode;
UIKIT_EXTERN NSString *const MCRPhotoPickerControllerPhotoMetadata;
UIKIT_EXTERN NSString *const MCRPhotoPickerDidFinishPickingNotification; // Notification key used when photo picked

@interface MCRPhotoPickerControllerConstants : NSObject
@end

typedef NS_OPTIONS(NSUInteger, MCRPhotoPickerControllerService) {
    MCRPhotoPickerControllerService500px = (1 << 0),            // 500px
    MCRPhotoPickerControllerServiceShutterstock = (1 << 1),     // Shutterstock
    MCRPhotoPickerControllerServiceFlickr = (1 << 2) ,           // Flickr
    MCRPhotoPickerControllerServiceFlashFoto  = (1 << 3)         // FlashFoto
};

typedef NS_ENUM(NSInteger, MCRPhotoEditViewControllerCropMode) {
    MCRPhotoEditViewControllerCropModeNone = -1,
    MCRPhotoEditViewControllerCropModeSquare = 0,
    MCRPhotoEditViewControllerCropModeCircular
};

UIKIT_EXTERN NSString *NSStringFromService(MCRPhotoPickerControllerService service);
UIKIT_EXTERN NSArray *NSArrayFromServices(MCRPhotoPickerControllerService services);
UIKIT_EXTERN MCRPhotoPickerControllerService MCRPhotoServiceFromName(NSString *name);
UIKIT_EXTERN MCRPhotoPickerControllerService MCRFirstPhotoServiceFromPhotoServices(MCRPhotoPickerControllerService services);
UIKIT_EXTERN NSString *NSStringFromCropMode(MCRPhotoEditViewControllerCropMode mode);

