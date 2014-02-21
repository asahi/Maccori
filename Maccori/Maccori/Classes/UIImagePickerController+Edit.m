//
//  UIImagePickerController+Edit.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "UIImagePickerController+Edit.h"

static MCRPhotoEditViewControllerCropMode _editingMode;

@implementation UIImagePickerController (Edit)

- (void)setEditingMode:(MCRPhotoEditViewControllerCropMode)mode
{
    _editingMode = mode;
    
    switch (mode) {
        case MCRPhotoEditViewControllerCropModeSquare:
            self.allowsEditing = YES;
            break;
            
        case MCRPhotoEditViewControllerCropModeCircular:
            self.allowsEditing = NO;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPickImage:) name:MCRPhotoPickerDidFinishPickingNotification object:nil];
            break;
            
        case MCRPhotoEditViewControllerCropModeNone:
            self.allowsEditing = NO;
            [[NSNotificationCenter defaultCenter] removeObserver:self name:MCRPhotoPickerDidFinishPickingNotification object:nil];
            break;
    }
}

- (MCRPhotoEditViewControllerCropMode)editingMode
{
    return _editingMode;
}

- (void)didPickImage:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(imagePickerController:didFinishPickingMediaWithInfo:)]){
        
        if ([[notification.userInfo allKeys] containsObject:UIImagePickerControllerEditedImage]) {
            self.editingMode = MCRPhotoEditViewControllerCropModeNone;
        }
        
        [self.delegate imagePickerController:self didFinishPickingMediaWithInfo:notification.userInfo];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

@end
