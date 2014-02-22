//
//  MCRPhotoEditViewController.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoEditViewController.h"
#import "MCRPhotoDisplayViewController.h"
#import "MCRPhotoMetadata.h"

#import "UIImageView+WebCache.h"

#define kInnerEdgeInset 15.0

static CGFloat _lastZoomScale;

typedef NS_ENUM(NSInteger, MCRPhotoAspect) {
    MCRPhotoAspectUnknown,
    MCRPhotoAspectSquare,
    MCRPhotoAspectVerticalRectangle,
    MCRPhotoAspectHorizontalRectangle
};


@interface MCRPhotoEditViewController () <UIScrollViewDelegate>

/* The photo metadata data object. */
@property (nonatomic, weak) MCRPhotoMetadata *photoMetadata;
@property (nonatomic, strong) UIImage *editingImage;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, strong) UIView *bottomView;
@end

@implementation MCRPhotoEditViewController
@synthesize photoMetadata = _photoMetadata;
@synthesize cropMode = _cropMode;
@synthesize cropSize = _cropSize;

- (instancetype)initWithPhotoMetadata:(MCRPhotoMetadata *)metadata cropMode:(MCRPhotoEditViewControllerCropMode)mode;
{
    self = [super init];
    if (self) {
        _photoMetadata = metadata;
        _cropMode = mode;
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image cropMode:(MCRPhotoEditViewControllerCropMode)mode
{
    self = [super init];
    if (self) {
        _editingImage = [image copy];
        _cropMode = mode;
    }
    return self;
}

+ (void)editImage:(UIImage *)image cropMode:(MCRPhotoEditViewControllerCropMode)mode inNavigationController:(UINavigationController *)controller
{
    MCRPhotoEditViewController *editController = [[self alloc] initWithImage:image cropMode:mode];
    [controller pushViewController:editController animated:YES];
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor blackColor];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.bottomView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];

    UIImageView *maskImageView = [[UIImageView alloc] initWithImage:[self overlayMask]];
    [self.view insertSubview:maskImageView aboveSubview:_scrollView];
    
    if (!_imageView.image) {
        
        __weak UIButton *_button = _acceptButton;
        _button.enabled = NO;
        
        __weak MCRPhotoEditViewController *_self = self;
        
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityIndicatorView.center = CGPointMake(roundf(_bottomView.frame.size.width/2), roundf(_bottomView.frame.size.height/2));
        [activityIndicatorView startAnimating];
        [_bottomView addSubview:activityIndicatorView];
        
        [_imageView setImageWithURL:_photoMetadata.sourceURL placeholderImage:nil
                            options:SDWebImageCacheMemoryOnly|SDWebImageProgressiveDownload|SDWebImageRetryFailed
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType){
                              if (!error) _button.enabled = YES;
                              [activityIndicatorView removeFromSuperview];
                              
                              [_self updateScrollViewContentInset];
                          }];
    }
    else {
        [self updateScrollViewContentInset];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}


#pragma mark - Getter methods

- (MCRPhotoPickerController *)navigationController
{
    return (MCRPhotoPickerController *)[super navigationController];
}

- (UIScrollView *)scrollView
{
    if (!_scrollView)
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.maximumZoomScale = 2.0;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.image = _editingImage;
        
        [_scrollView addSubview:_imageView];
        [_scrollView setZoomScale:_scrollView.minimumZoomScale];
    }
    return _scrollView;
}

- (UIView *)bottomView
{
    if (!_bottomView)
    {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-72.0, self.view.bounds.size.width, 72.0)];
        
        _cancelButton = [self buttonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [_cancelButton addTarget:self action:@selector(cancelEdition:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomView addSubview:_cancelButton];
        
        _acceptButton = [self buttonWithTitle:NSLocalizedString(@"Choose", nil)];
        [_acceptButton addTarget:self action:@selector(acceptEdition:) forControlEvents:UIControlEventTouchUpInside];
        [_acceptButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.5] forState:UIControlStateDisabled];
        [_bottomView addSubview:_acceptButton];
        
        CGRect rect = _cancelButton.frame;
        rect.origin = CGPointMake(13.0, roundf(_bottomView.frame.size.height/2-_cancelButton.frame.size.height/2));
        [_cancelButton setFrame:rect];
        
        rect = _acceptButton.frame;
        rect.origin = CGPointMake(roundf(_bottomView.frame.size.width-_acceptButton.frame.size.width-13.0), roundf(_bottomView.frame.size.height/2-_acceptButton.frame.size.height/2));
        [_acceptButton setFrame:rect];
        
        if (_cropMode == MCRPhotoEditViewControllerCropModeCircular) {
            
            UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            topLabel.text = NSLocalizedString(@"Move and Scale", nil);
            topLabel.textColor = [UIColor whiteColor];
            topLabel.font = [UIFont systemFontOfSize:18.0];
            [topLabel sizeToFit];
            
            rect = topLabel.frame;
            rect.origin = CGPointMake(self.view.bounds.size.width/2-rect.size.width/2, 64.0);
            topLabel.frame = rect;
            [self.view addSubview:topLabel];
        }
    }
    return _bottomView;
}

- (UIButton *)buttonWithTitle:(NSString *)title
{
    UIButton *button = [[UIButton alloc] init];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [button setTitleEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, 0)];
    [button.titleLabel setFont:[UIFont systemFontOfSize:18.0]];
    [button sizeToFit];
    return button;
}

- (CGSize)cropSize
{
    CGSize viewSize = self.view.bounds.size;
    
    switch (_cropMode) {
        case MCRPhotoEditViewControllerCropModeSquare:
        case MCRPhotoEditViewControllerCropModeCircular:
        default:
            return CGSizeMake(viewSize.width, viewSize.width);
    }
}

- (CGRect)cropRect
{
    CGSize viewSize = self.navigationController.view.bounds.size;
    CGSize cropSize = [self cropSize];
    CGFloat verticalMargin = (viewSize.height-cropSize.height)/2;
    return CGRectMake(0.0, verticalMargin, cropSize.width, cropSize.height);
}

- (CGSize)imageSize
{
    return CGSizeAspectFit(_imageView.image.size,_imageView.frame.size);
}

CGSize CGSizeAspectFit(CGSize aspectRatio, CGSize boundingSize)
{
    float hRatio = boundingSize.width / aspectRatio.width;
    float vRation = boundingSize.height / aspectRatio.height;
    if (hRatio < vRation) {
        boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
    }
    else if (vRation < hRatio) {
        boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
    }
    return boundingSize;
}

MCRPhotoAspect photoAspectFromSize(CGSize aspectRatio)
{
    if (aspectRatio.width > aspectRatio.height) {
        return MCRPhotoAspectHorizontalRectangle;
    }
    else if (aspectRatio.width < aspectRatio.height) {
        return MCRPhotoAspectVerticalRectangle;
    }
    else if (aspectRatio.width == aspectRatio.height) {
        return MCRPhotoAspectSquare;
    }
    else {
        return MCRPhotoAspectUnknown;
    }
}

- (UIImage *)overlayMask
{
    switch (_cropMode) {
        case MCRPhotoEditViewControllerCropModeSquare:
            return [self squareOverlayMask];
        case MCRPhotoEditViewControllerCropModeCircular:
            return [self circularOverlayMask];
        default:
            return nil;
    }
}

- (UIImage *)squareOverlayMask
{
    // Constants
    CGSize size = self.navigationController.view.bounds.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat margin = (height-[self cropSize].height)/2;
    CGFloat lineWidth = 1.0;
    UIColor *fillColor = [UIColor colorWithWhite:0 alpha:0.5];
    UIColor *strokeColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);

    // Create the bezier path & drawing
    UIBezierPath *clipPath = [UIBezierPath bezierPath];
    [clipPath moveToPoint:CGPointMake(width, margin)];
    [clipPath addLineToPoint:CGPointMake(0, margin)];
    [clipPath addLineToPoint:CGPointMake(0, 0)];
    [clipPath addLineToPoint:CGPointMake(width, 0)];
    [clipPath addLineToPoint:CGPointMake(width, margin)];
    [clipPath closePath];
    [clipPath moveToPoint:CGPointMake(width, height)];
    [clipPath addLineToPoint:CGPointMake(0, height)];
    [clipPath addLineToPoint:CGPointMake(0, [self cropSize].height+margin)];
    [clipPath addLineToPoint:CGPointMake(width, [self cropSize].height+margin)];
    [clipPath addLineToPoint:CGPointMake(width, height)];
    [clipPath closePath];
    [fillColor setFill];
    [clipPath fill];
    
    // Add the square crop
    CGRect rect = CGRectMake(lineWidth/2, margin+lineWidth/2, width-lineWidth, [self cropSize].height-lineWidth);
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:rect];
    [strokeColor setStroke];
    maskPath.lineWidth = lineWidth;
    [maskPath stroke];
    
    //Create the image using the current context.
    UIImage *_maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return _maskedImage;
}

- (UIImage *)circularOverlayMask
{
    // Constants
    CGRect rect = self.navigationController.view.bounds;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    
    CGFloat diameter = width-(kInnerEdgeInset*2);
    CGFloat radius = diameter/2;
    CGPoint center = CGPointMake(width/2, height/2);
    UIColor *fillColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    // Create the image context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    // Create the bezier paths
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:rect];
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x-radius, center.y-radius, diameter, diameter)];
    
    [clipPath appendPath:maskPath];
    clipPath.usesEvenOddFillRule = YES;
    
    [clipPath addClip];
    [fillColor setFill];
    [clipPath fill];
    
    UIImage *_maskedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return _maskedImage;
}

/*
 * The final edited photo rendering.
 */
- (UIImage *)editedPhoto
{
    UIImage *_image = nil;
    
    // Constant sizes
    CGRect bounds = self.navigationController.view.bounds;
    
    CGRect cropRect = [self cropRect];

    CGFloat verticalMargin = (bounds.size.height-cropRect.size.height)/2;

    cropRect.origin.x = -_scrollView.contentOffset.x;
    cropRect.origin.y = -_scrollView.contentOffset.y - verticalMargin;

    UIGraphicsBeginImageContextWithOptions(cropRect.size, NO, 0);{
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(context, cropRect.origin.x, cropRect.origin.y);
        [_scrollView.layer renderInContext:context];
        
        _image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    if (_cropMode == MCRPhotoEditViewControllerCropModeCircular) {
        
        CGFloat diameter = bounds.size.width-(kInnerEdgeInset*2);
        CGRect circulatRect = CGRectMake(0, 0, diameter, diameter);
        
        CGFloat increment = 1.0/(((kInnerEdgeInset*2)*100.0)/bounds.size.width);
        CGFloat scale = 1.0 + round(increment * 10) / 10.0;
        
        UIGraphicsBeginImageContextWithOptions(circulatRect.size, NO, 0.0);{
            
            UIBezierPath *maskPath = [UIBezierPath bezierPathWithOvalInRect:circulatRect];
            [maskPath addClip];

            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, -kInnerEdgeInset, -kInnerEdgeInset);
            CGContextScaleCTM(context, scale, scale);

            // Draw the image
            [_image drawInRect:circulatRect];
            
            CGPathRef path = [maskPath CGPath];
            CGContextAddPath(context, path);

            _image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }

    return _image;
}


#pragma mark - Setter

- (void)setCropSize:(CGSize)cropSize
{
    CGSize viewSize = self.view.bounds.size;
    CGFloat cropHeight = roundf((cropSize.height * viewSize.width) / cropSize.width);
    _cropSize = CGSizeMake(cropSize.width, cropHeight);
}


#pragma mark - MCRPhotoEditViewController methods

- (void)updateScrollViewContentInset
{
    CGFloat maskHeight = (_cropMode == MCRPhotoEditViewControllerCropModeCircular) ? [self cropSize].width-(kInnerEdgeInset*2) : [self cropSize].height;
    CGSize imageSize = [self imageSize];
    
    CGFloat hInset = (_cropMode == MCRPhotoEditViewControllerCropModeCircular) ? kInnerEdgeInset : 0.0;
    CGFloat vInset = fabs((maskHeight-imageSize.height)/2);
    
    if (vInset == 0) vInset = 0.5;
    
    _scrollView.contentInset =  UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
}

- (void)acceptEdition:(id)sender
{
    dispatch_queue_t exampleQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(exampleQueue, ^{
        
        UIImage *editedPhoto = [self editedPhoto];
        CGRect cropRect = [self cropRect];
        
        dispatch_queue_t queue = dispatch_get_main_queue();
        dispatch_async(queue, ^{
            
            if (editedPhoto && !CGRectEqualToRect(cropRect, CGRectZero)) {
                
                [MCRPhotoEditViewController didFinishPickingOriginalImage:_imageView.image
                                                              editedImage:editedPhoto
                                                                 cropRect:cropRect
                                                                 cropMode:self.cropMode
                                                            photoMetadata:self.photoMetadata];
            }
        });
    });
}

- (void)cancelEdition:(id)sender
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }
}

+ (void)didFinishPickingOriginalImage:(UIImage *)originalImage
                          editedImage:(UIImage *)editedImage
                             cropRect:(CGRect)cropRect
                             cropMode:(MCRPhotoEditViewControllerCropMode)cropMode
                        photoMetadata:(MCRPhotoMetadata *)metadata;
{
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                     [NSValue valueWithCGRect:cropRect], UIImagePickerControllerCropRect,
                                     @"public.image", UIImagePickerControllerMediaType,
                                     NSStringFromCropMode(cropMode), MCRPhotoPickerControllerCropMode,
                                     nil];
    
    if (originalImage) [userInfo setObject:originalImage forKey:UIImagePickerControllerOriginalImage];
    if (editedImage) [userInfo setObject:editedImage forKey:UIImagePickerControllerEditedImage];
    if (metadata) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:metadata.serviceName forKey:@"source_name"];
        if (metadata.Id) [attributes setObject:metadata.Id forKey:@"source_id"];
        if (metadata.detailURL) [attributes setObject:metadata.detailURL forKey:@"source_detail_url"];
        if (metadata.sourceURL) [attributes setObject:metadata.sourceURL forKey:@"source_url"];
        if (metadata.authorUsername) [attributes setObject:metadata.authorUsername forKey:@"author_username"];
        if (metadata.authorProfileURL) [attributes setObject:metadata.authorProfileURL forKey:@"author_profile_url"];
        [userInfo setObject:attributes forKey:MCRPhotoPickerControllerPhotoMetadata];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MCRPhotoPickerDidFinishPickingNotification object:nil userInfo:userInfo];
}


#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    _lastZoomScale = _scrollView.zoomScale;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    //[self updateScrollViewContentInset];
}

- (void)dealloc
{
    _imageView.image = nil;
    _imageView = nil;
    _scrollView = nil;
}


@end
