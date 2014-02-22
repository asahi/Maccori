//
//  RootViewController.h
//  Sample
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MCRPhotoPickerController.h"

@interface RootViewController : UIViewController <UIActionSheetDelegate, UINavigationControllerDelegate,
                                                UIImagePickerControllerDelegate, MCRPhotoPickerControllerDelegate,
                                                UIPopoverControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *faceView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIButton *button;

- (IBAction)pressButton:(id)sender;

@end
