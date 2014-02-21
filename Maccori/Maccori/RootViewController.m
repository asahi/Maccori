//
//  RootViewController.m
//  Sample
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "RootViewController.h"
#import "MCRPhotoPickerController.h"
#import "UIImagePickerController+Edit.h"

#import "Private.h"

@interface RootViewController () {
    NSDictionary *_photoPayload;
}
@end

@implementation RootViewController

+ (void)initialize
{
    [MCRPhotoPickerController registerService:MCRPhotoPickerControllerService500px
                                  consumerKey:k500pxConsumerKey
                               consumerSecret:k500pxConsumerSecret];

    [MCRPhotoPickerController registerService:MCRPhotoPickerControllerServiceFlickr
                                  consumerKey:kFlickrConsumerKey
                               consumerSecret:kFlickrConsumerSecret];

}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIGraphicsBeginImageContextWithOptions(_button.frame.size, NO, 0);
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, _button.frame.size.width, _button.frame.size.height)];
    [[UIColor colorWithWhite:0 alpha:0.25] setFill];
    [clipPath fill];
    [_button setBackgroundImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateHighlighted];
    UIGraphicsEndImageContext();
}


#pragma mark - ViewController methods

- (IBAction)pressButton:(UIButton *)button
{
    UIActionSheet *actionSheet = [UIActionSheet new];

    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        [actionSheet addButtonWithTitle:@"Take Photo"];
    }

    [actionSheet addButtonWithTitle:@"Choose Photo"];
    [actionSheet addButtonWithTitle:@"Search Photo"];

    if (_imageView.image) {
        [actionSheet addButtonWithTitle:@"Edit Photo"];
        [actionSheet addButtonWithTitle:@"Delete Photo"];
    }

    [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:@"Cancel"]];
    [actionSheet setDelegate:self];

    [actionSheet showFromRect:button.frame inView:self.view animated:YES];
}

- (void)presentImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.editingMode = MCRPhotoEditViewControllerCropModeCircular;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)presentPhotoPicker
{
    MCRPhotoPickerController *picker = [[MCRPhotoPickerController alloc] init];
    picker.supportedServices = MCRPhotoPickerControllerService500px | MCRPhotoPickerControllerServiceFlickr;
    picker.allowsEditing = YES;
    picker.editingMode = MCRPhotoEditViewControllerCropModeSquare;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)presentPhotoEditor
{
    UIImage *image = [_photoPayload objectForKey:UIImagePickerControllerOriginalImage];

    MCRPhotoPickerController *editor = [[MCRPhotoPickerController alloc] initWithEditableImage:image];
    editor.editingMode = [[_photoPayload objectForKey:MCRPhotoPickerControllerCropMode] integerValue];
    editor.delegate = self;
    [self presentViewController:editor animated:YES completion:NULL];
}

- (void)updateImage:(NSDictionary *)userInfo
{
    _photoPayload = userInfo;

    NSLog(@"OriginalImage : %@",[userInfo objectForKey:UIImagePickerControllerOriginalImage]);
    NSLog(@"EditedImage : %@",[userInfo objectForKey:UIImagePickerControllerEditedImage]);
    NSLog(@"MediaType : %@",[userInfo objectForKey:UIImagePickerControllerMediaType]);
    NSLog(@"CropRect : %@", NSStringFromCGRect([[userInfo objectForKey:UIImagePickerControllerCropRect] CGRectValue]));
    NSLog(@"CropMode : %@", [userInfo objectForKey:MCRPhotoPickerControllerCropMode]);
    NSLog(@"PhotoAttributes : %@",[userInfo objectForKey:MCRPhotoPickerControllerPhotoMetadata]);

    UIImage *image = [userInfo objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [userInfo objectForKey:UIImagePickerControllerOriginalImage];

    _imageView.image = image;
    [_button setTitle:nil forState:UIControlStateNormal];
}

- (void)saveImage:(NSDictionary *)userInfo
{
    UIImage *image = [userInfo objectForKey:UIImagePickerControllerEditedImage];
    if (!image) image = [userInfo objectForKey:UIImagePickerControllerOriginalImage];

    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([buttonTitle isEqualToString:@"Take Photo"]) {
        [self presentImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
    }
    else if ([buttonTitle isEqualToString:@"Choose Photo"]) {
        [self presentImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    else if ([buttonTitle isEqualToString:@"Search Photo"]) {
        [self presentPhotoPicker];
    }
    else if ([buttonTitle isEqualToString:@"Edit Photo"]) {
        [self presentPhotoEditor];
    }
    else if ([buttonTitle isEqualToString:@"Delete Photo"]) {
        [_button setTitle:@"Tap Here" forState:UIControlStateNormal];
        _imageView.image = nil;
        _photoPayload = nil;
    }
}

#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (picker.editingMode == MCRPhotoEditViewControllerCropModeCircular) {

        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [MCRPhotoEditViewController editImage:image cropMode:picker.editingMode inNavigationController:picker];
    }
    else {
        [self updateImage:info];
        [picker dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - MCRPhotoPickerControllerDelegate methods

- (void)photoPickerController:(MCRPhotoPickerController *)picker didFinishPickingPhotoWithInfo:(NSDictionary *)info
{
    [self updateImage:info];
    [self saveImage:info];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)photoPickerControllerDidCancel:(MCRPhotoPickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
