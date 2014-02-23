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
                                                UIPopoverControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *faceView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, weak) IBOutlet UIButton *plusFaceButton;
@property (nonatomic, weak) IBOutlet UIButton *checkStatusButton;
@property (nonatomic, weak) IBOutlet UIButton *mergeButton;
- (IBAction)pressButton:(id)sender;

@end
