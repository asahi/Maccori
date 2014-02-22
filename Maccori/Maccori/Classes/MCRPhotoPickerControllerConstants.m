//
//  MCRPhotoPickerControllerConstants.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoPickerControllerConstants.h"

NSString *const MCRPhotoPickerControllerCropMode = @"MCRPhotoPickerControllerCropMode";
NSString *const MCRPhotoPickerControllerPhotoMetadata = @"MCRPhotoPickerControllerPhotoMetadata";

NSString *const MCRPhotoPickerDidFinishPickingNotification = @"MCRPhotoPickerDidFinishPickingNotification";


@implementation MCRPhotoPickerControllerConstants
@end

NSString *NSStringFromService(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:
            return @"500px";
        case MCRPhotoPickerControllerServiceShutterstock:
            return @"Shutterstock";
        case MCRPhotoPickerControllerServiceFlickr:
            return @"Flickr";
        case MCRPhotoPickerControllerServiceFlashFoto:
            return @"FlashFoto";
        default:
            return nil;
    }
}

MCRPhotoPickerControllerService MCRPhotoServiceFromName(NSString *name)
{
    if ([name isEqualToString:NSStringFromService(MCRPhotoPickerControllerService500px)])
        return MCRPhotoPickerControllerService500px;
    if ([name isEqualToString:NSStringFromService(MCRPhotoPickerControllerServiceShutterstock)])
        return MCRPhotoPickerControllerServiceShutterstock;
    if ([name isEqualToString:NSStringFromService(MCRPhotoPickerControllerServiceFlickr)])
        return MCRPhotoPickerControllerServiceFlickr;
    if ([name isEqualToString:NSStringFromService(MCRPhotoPickerControllerServiceFlashFoto)])
        return MCRPhotoPickerControllerServiceFlashFoto;

    return -1;
}

MCRPhotoPickerControllerService MCRFirstPhotoServiceFromPhotoServices(MCRPhotoPickerControllerService services)
{
    if ((services & MCRPhotoPickerControllerService500px) > 0) {
        return MCRPhotoPickerControllerService500px;
    }
    if ((services & MCRPhotoPickerControllerServiceShutterstock) > 0) {
        return MCRPhotoPickerControllerServiceShutterstock;
    }
    if ((services & MCRPhotoPickerControllerServiceFlickr) > 0) {
        return MCRPhotoPickerControllerServiceFlickr;
    }
    return 0;
}

NSArray *NSArrayFromServices(MCRPhotoPickerControllerService services)
{
    NSMutableArray *titles = [NSMutableArray array];
    
    if ((services & MCRPhotoPickerControllerService500px) > 0) {
        [titles addObject:NSStringFromService(MCRPhotoPickerControllerService500px)];
    }
    if ((services & MCRPhotoPickerControllerServiceShutterstock) > 0) {
        [titles addObject:NSStringFromService(MCRPhotoPickerControllerServiceShutterstock)];
    }
    if ((services & MCRPhotoPickerControllerServiceFlickr) > 0) {
        [titles addObject:NSStringFromService(MCRPhotoPickerControllerServiceFlickr)];
    }
    return [NSArray arrayWithArray:titles];
}

NSString *NSStringFromCropMode(MCRPhotoEditViewControllerCropMode mode)
{
    switch (mode) {
        case MCRPhotoEditViewControllerCropModeSquare:      return @"square";
        default:                                            return @"none";
    }
}
