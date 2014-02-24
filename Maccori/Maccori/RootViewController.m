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
#import "MCRResultPhotoViewController.h"
#import <SVProgressHUD/SVProgressHUD.h>

static NSString *COORDIPHOTO = @"coordiphoto";
static NSString *FACEPHOTO = @"facephoto";

@interface RootViewController ()<AFPhotoEditorControllerDelegate> {
    NSDictionary *_photoPayload;
    NSString *_mugshotTargetImageID;
    NSString *_backgroundImageID;
    NSString *_resultImageID;
    MCRPhotoServiceClient *_flashFotoClient;
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
        [actionSheet addButtonWithTitle:@"Search Photo"];
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

- (IBAction)checkMugshotStatus:(UIButton *)button {
    if (_mugshotTargetImageID) {
        if (!_flashFotoClient) {
            _flashFotoClient = [[MCRPhotoServiceClient alloc] initWithService:MCRPhotoPickerControllerServiceFlashFoto];
        }
        NSDictionary *parameters = @{ @"partner_username":kFlashFotoAPIUsername, @"partner_apikey" : kFlashFotoAPIKey};
        NSString *path = [NSString stringWithFormat:@"mugshot_status/%@", _mugshotTargetImageID];
        [_flashFotoClient getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id response) {
            NSData *data = [_flashFotoClient processData:response];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments error:nil];
            if ([json[@"mugshot_status"] isEqualToString:@"pending"]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not yet"
                                                                message:@""
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            else if([json[@"mugshot_status"] isEqualToString:@"finished"]) {
                [SVProgressHUD showWithStatus:@"Finish mugshot. we can see resulting mask." maskType:SVProgressHUDMaskTypeClear];
                NSDictionary *param = @{ @"version" : @"MugshotMasked" ,
                                              @"partner_username":kFlashFotoAPIUsername,
                                              @"partner_apikey" : kFlashFotoAPIKey};
                NSString *path = [NSString stringWithFormat:@"get/%@", _mugshotTargetImageID];
                [_flashFotoClient getPath:path parameters:param success:^(AFHTTPRequestOperation *operation, id response) {
                    [SVProgressHUD dismiss];
                    NSData *data = [_flashFotoClient processData:response];
                    UIImage *resultImage = [[UIImage alloc]initWithData:data];
                    _faceView.image = resultImage;
                    _checkStatusButton.hidden = YES;
                    _mergeButton.hidden = NO;
                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                    [SVProgressHUD dismiss];
                }];


            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait please"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
}


- (IBAction)merge:(UIButton *)button {
    if (_mugshotTargetImageID && _backgroundImageID) {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Uploading...", nil) maskType:SVProgressHUDMaskTypeClear];

        [_flashFotoClient mergePhotos:_mugshotTargetImageID background:_backgroundImageID completion:^(NSDictionary *imageVersion, NSDictionary *imageDict, NSError *err) {

            [_flashFotoClient getPhoto:imageDict[@"image_id"] completion:^(UIImage* image, NSError *error){
                if (image) {
                    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
                    [SVProgressHUD dismiss];
                    _imageView.image = image;
                    [_imageView layoutIfNeeded];
                    _plusFaceButton.hidden = NO;
                }
            }];
            [SVProgressHUD dismiss];
        }];
    }
//         getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id response) {
//            NSData *data = [_flashFotoClient processData:response];
//            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments error:nil];
//            if ([json[@"mugshot_status"] isEqualToString:@"pending"]) {
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not yet"
//                                                                message:@""
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//                [alert show];
//            }
//            else if([json[@"mugshot_status"] isEqualToString:@"finished"]) {
//                [SVProgressHUD showWithStatus:@"Finish mugshot. we can see resulting mask." maskType:SVProgressHUDMaskTypeClear];
//                NSDictionary *param = @{ @"version" : @"MugshotMasked" ,
//                                         @"partner_username":kFlashFotoAPIUsername,
//                                         @"partner_apikey" : kFlashFotoAPIKey};
//                NSString *path = [NSString stringWithFormat:@"get/%@", _mugshotTargetImageID];
//                [_flashFotoClient getPath:path parameters:param success:^(AFHTTPRequestOperation *operation, id response) {
//                    [SVProgressHUD dismiss];
//                    NSData *data = [_flashFotoClient processData:response];
//                    UIImage *resultImage = [[UIImage alloc]initWithData:data];
//                    _faceView.image = resultImage;
//                    _checkStatusButton.hidden = YES;
//                    _mergeButton.hidden = NO;
//                } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                    [SVProgressHUD dismiss];
//                }];
//
//
//            }
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            if (error) {
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Wait please"
//                                                                message:error.localizedDescription
//                                                               delegate:nil
//                                                      cancelButtonTitle:@"OK"
//                                                      otherButtonTitles:nil];
//                [alert show];
//            }
//        }];
//    }
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
    picker.editingMode = MCRPhotoEditViewControllerCropModeSquare;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)presentPhotoEditor
{
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage:_imageView.image];
    [editorController setDelegate:self];
    [self presentViewController:editorController animated:YES completion:NULL];
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

    if (!_flashFotoClient) {
        _flashFotoClient = [[MCRPhotoServiceClient alloc] initWithService:MCRPhotoPickerControllerServiceFlashFoto];
    }
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Uploading...", nil) maskType:SVProgressHUDMaskTypeClear];

    [_flashFotoClient postPhoto:image completion:^(NSDictionary *imageVersion, NSDictionary *imageDict, NSError *err) {
        _imageView.image = image;
        [_button setTitle:nil forState:UIControlStateNormal];

        _backgroundImageID = imageDict[@"image_id"];
        [SVProgressHUD dismiss];
    }];
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
    if (!_flashFotoClient) {
        _flashFotoClient = [[MCRPhotoServiceClient alloc] initWithService:MCRPhotoPickerControllerServiceFlashFoto];
    }
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Uploading...", nil) maskType:SVProgressHUDMaskTypeClear];

    [_flashFotoClient postPhoto:image completion:^(NSDictionary *imageVersion, NSDictionary *imageDict, NSError *err) {
        _faceView.image = image;
        _mugshotTargetImageID = imageDict[@"image_id"];
        [SVProgressHUD dismiss];

        [self displayUploadSuccesMessage];
    }];
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


- (void)displayUploadSuccesMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Photo has already"
                                                        message:@"Removes the background?"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
    [alertView show];
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

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && _mugshotTargetImageID) {
        NSLog(@"%@",_mugshotTargetImageID);
        if (!_flashFotoClient) {
            _flashFotoClient = [[MCRPhotoServiceClient alloc] initWithService:MCRPhotoPickerControllerServiceFlashFoto];
        }
        [SVProgressHUD showWithStatus:@"Removing the background..." maskType:SVProgressHUDMaskTypeClear];
        NSDictionary *parameters = @{ @"partner_username":kFlashFotoAPIUsername, @"partner_apikey" : kFlashFotoAPIKey};
        NSString *path = [NSString stringWithFormat:@"mugshot/%@", _mugshotTargetImageID];
        [_flashFotoClient getPath:path parameters:parameters success:^(AFHTTPRequestOperation *operation, id response) {
            [_plusFaceButton setHidden:YES];
            [_checkStatusButton setHidden:NO];
            [SVProgressHUD dismiss];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [SVProgressHUD dismiss];
            if (error) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:error.localizedDescription
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }];
    }
}


#pragma mark - Avail methods

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image
{
    _imageView.image = image;
                        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    [editor dismissViewControllerAnimated:YES completion:NULL];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor
{
    [editor dismissViewControllerAnimated:YES completion:NULL];
}


@end
