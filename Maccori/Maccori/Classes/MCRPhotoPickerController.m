//
//  MCRPhotoPickerController.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoPickerController.h"
#import "MCRPhotoDisplayViewController.h"
#import "MCRPhotoServiceFactory.h"
#import "AFPhotoEditorController.h"

#import <MobileCoreServices/UTCoreTypes.h>

@interface MCRPhotoPickerController ()
@property (nonatomic, getter = isEditing) BOOL editing;
@property (nonatomic, assign) UIImage *editingImage;
@end

@implementation MCRPhotoPickerController

- (id)init
{
    self = [super init];
    if (self) {
        _allowsEditing = NO;
        _supportedServices = MCRPhotoPickerControllerService500px | MCRPhotoPickerControllerServiceShutterstock | MCRPhotoPickerControllerServiceFlickr;
    }
    return self;
}

- (instancetype)initWithEditableImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        _editingImage = image;
        _editing = YES;
    }
    return self;
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];

    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeTop;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didPickPhoto:) name:MCRPhotoPickerDidFinishPickingNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.isEditing) [self showPhotoEditorController];
    else [self showPhotoDisplayController];
}

#pragma mark - Setter methods

- (void)setSupportedServices:(MCRPhotoPickerControllerService)services
{
    NSAssert(services > 0, @"You must set at least 1 service to be supported.");
    _supportedServices = services;
}

+ (void)registerService:(MCRPhotoPickerControllerService)service consumerKey:(NSString *)key consumerSecret:(NSString *)secret
{
    [MCRPhotoServiceFactory setConsumerKey:key consumerSecret:secret service:service];
}


#pragma mark - MCRPhotoPickerController methods

- (void)showPhotoDisplayController
{
    [self setViewControllers:nil];

    MCRPhotoDisplayViewController *controller = [[MCRPhotoDisplayViewController alloc] init];
    controller.searchTerm = _initialSearchTerm;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicker:)];
    [controller.navigationItem setRightBarButtonItem:cancel];
    [self setViewControllers:@[controller]];
}

- (void)showPhotoEditorController
{
    [self setViewControllers:nil];

    MCRPhotoEditViewController *controller = [[MCRPhotoEditViewController alloc] initWithImage:_editingImage cropMode:self.editingMode];
    [self setViewControllers:@[controller]];
}

- (void)didPickPhoto:(NSNotification *)notification
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPickerController:didFinishPickingPhotoWithInfo:)]){
        [self.delegate photoPickerController:self didFinishPickingPhotoWithInfo:notification.userInfo];
    }
}

- (void)cancelPicker:(id)sender
{
    MCRPhotoDisplayViewController *controller = (MCRPhotoDisplayViewController *)[self.viewControllers objectAtIndex:0];
    if ([controller respondsToSelector:@selector(stopLoadingRequest)]) {
        [controller stopLoadingRequest];
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(photoPickerControllerDidCancel:)]) {
        [self.delegate photoPickerControllerDidCancel:self];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
