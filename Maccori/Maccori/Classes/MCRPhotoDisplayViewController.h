//
//  MCRPhotoDisplayController.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCRPhotoPickerController;

@interface MCRPhotoDisplayViewController : UICollectionViewController

@property (nonatomic, readonly) MCRPhotoPickerController *navigationController;
@property (nonatomic, strong) NSString *searchTerm;
@property (nonatomic) NSInteger columnCount;
@property (nonatomic) NSInteger rowCount;
@property (nonatomic, getter = isLoading) BOOL loading;

- (void)stopLoadingRequest;

@end
