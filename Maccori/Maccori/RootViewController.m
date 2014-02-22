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
#import "AFPhotoEditorController.h"
#import "MCRPhotoServiceClient.h"

static NSString *COORDIPHOTO = @"coordiphoto";
static NSString *FACEPHOTO = @"facephoto";

@interface RootViewController ()<AFPhotoEditorControllerDelegate> {
    NSDictionary *_photoPayload;
}
@end

@implementation RootViewController

+ (void)initialize
{
    [MCRPhotoPickerController registerService:MCRPhotoPickerControllerService500px
                                  consumerKey:k500pxConsumerKey
                               consumerSecret:k500pxConsumerSecret];

    [MCRPhotoPickerController registerService:MCRPhotoPickerControllerServiceShutterstock
                                  consumerKey:kShutterStockAPIKey
                               consumerSecret:kShutterStockAPIUserName];

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
    if (!_imageView.image) {
        [self presentPhotoPicker];
        return;
    }
    UIActionSheet *actionSheet = [UIActionSheet new];
    actionSheet.title = COORDIPHOTO;

    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        [actionSheet addButtonWithTitle:@"Take Photo"];
    }
    [actionSheet addButtonWithTitle:@"Choose Photo"];

    if (_imageView.image) {
        [actionSheet addButtonWithTitle:@"Edit Photo"];
        [actionSheet addButtonWithTitle:@"Delete Photo"];
    }

    [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:@"Cancel"]];
    [actionSheet setDelegate:self];

    [actionSheet showFromRect:button.frame inView:self.view animated:YES];
}

- (IBAction)pressFaceButton:(UIButton *)button
{
    UIActionSheet *actionSheet = [UIActionSheet new];
    actionSheet.title = FACEPHOTO;

    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
        [actionSheet addButtonWithTitle:@"Take Photo"];
    }

    [actionSheet addButtonWithTitle:@"Choose Photo"];

    [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:@"Cancel"]];
    [actionSheet setDelegate:self];

    [actionSheet showFromRect:button.frame inView:self.view animated:YES];

}

- (void)presentImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType actionType:(NSString *)actionType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    if([actionType isEqualToString:COORDIPHOTO]) {
        picker.editingMode = MCRPhotoEditViewControllerCropModeSquare;
    }
    else if([actionType isEqualToString:FACEPHOTO]) {
        picker.editingMode = MCRPhotoEditViewControllerCropModeCircular;
    }
    picker.delegate = self;

    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)presentPhotoPicker
{
    MCRPhotoPickerController *picker = [[MCRPhotoPickerController alloc] init];
    picker.supportedServices = MCRPhotoPickerControllerService500px | MCRPhotoPickerControllerServiceShutterstock | MCRPhotoPickerControllerServiceFlickr;
    picker.allowsEditing = YES;
    picker.editingMode = MCRPhotoEditViewControllerCropModeNone;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)presentPhotoEditor
{
    MCRPhotoServiceClient *client = [[MCRPhotoServiceClient alloc] initWithService:MCRPhotoPickerControllerServiceFlashFoto];
    UIImage *image = [_photoPayload objectForKey:UIImagePickerControllerOriginalImage];

    [client postPhoto:image completion:^(NSDictionary *imageVersion, NSDictionary *image, NSError *err) {
        client
//        NSLog(@"ddddd");
    }];
//    MCRPhotoPickerController *editor = [[MCRPhotoPickerController alloc] initWithEditableImage:image];
//    editor.editingMode = [[_photoPayload objectForKey:MCRPhotoPickerControllerCropMode] integerValue];
//    editor.delegate = self;
//    [self presentViewController:editor animated:YES completion:NULL];
}

- (void)updateImage:(NSDictionary *)userInfo
{
    _photoPayload = userInfo;

    NSLog(@"CoordiImage");
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

- (void)updateFaceImage:(NSDictionary *)userInfo
{
    _photoPayload = userInfo;

    NSLog(@"FaceImage");
    NSLog(@"OriginalImage : %@",[userInfo objectForKey:UIImagePickerControllerOriginalImage]);
    NSLog(@"EditedImage : %@",[userInfo objectForKey:UIImagePickerControllerEditedImage]);
    NSLog(@"MediaType : %@",[userInfo objectForKey:UIImagePickerControllerMediaType]);
    NSLog(@"CropRect : %@", NSStringFromCGRect([[userInfo objectForKey:UIImagePickerControllerCropRect] CGRectValue]));
    NSLog(@"CropMode : %@", [userInfo objectForKey:MCRPhotoPickerControllerCropMode]);
    NSLog(@"PhotoAttributes : %@",[userInfo objectForKey:MCRPhotoPickerControllerPhotoMetadata]);

    UIImage *image = [userInfo objectForKey:UIImagePickerControllerOriginalImage];

    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:image];
    [editorController setDelegate:self];
    [self presentViewController:editorController animated:YES completion:NULL];
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
    NSString *actionTitle = actionSheet.title;

    if ([buttonTitle isEqualToString:@"Take Photo"]) {
        [self presentImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera actionType:actionTitle];
    }
    else if ([buttonTitle isEqualToString:@"Choose Photo"]) {
        [self presentImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary actionType:actionTitle];
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
        [picker dismissViewControllerAnimated:YES completion:^{
            [self updateFaceImage:info];
        }];

    }
    else if(picker.editingMode == MCRPhotoEditViewControllerCropModeSquare) {
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

#pragma mark - Avail methods

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    _faceView.image = image;
    [editor dismissViewControllerAnimated:YES completion:NULL];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    // Handle cancellation here
}

@end
