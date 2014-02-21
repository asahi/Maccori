//
//  MCRPhotoDisplayViewCell.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoDisplayViewCell.h"

@implementation MCRPhotoDisplayViewCell
@synthesize imageView = _imageView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundView = self.imageView;
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        
        self.selectedBackgroundView = [UIView new];
        self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    }
    return self;
}


#pragma mark - Getter methods

- (UIImageView *)imageView
{
    if (!_imageView)
    {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.clipsToBounds = YES;
        _imageView.userInteractionEnabled = NO;
    }
    return _imageView;
}


#pragma mark - UIView methods

- (void)setSelected:(BOOL)selected
{
    if (_imageView.image) {
        [super setSelected:selected];
    }
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_imageView.image) {
        [super setHighlighted:highlighted];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [_imageView cancelCurrentImageLoad];
}

@end
