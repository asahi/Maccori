//
//  MCRPhotoServiceClientProtocol.h
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DZNHTTPRequestCompletion)(NSArray *list, NSError *error);

@protocol MCRPhotoServiceClientProtocol <NSObject>

// Current photo service.
@property (nonatomic) MCRPhotoPickerControllerService service;
@property (nonatomic, readonly) BOOL loading;

// Searche tags related to a keyword string.
- (void)searchTagsWithKeyword:(NSString *)keyword completion:(DZNHTTPRequestCompletion)completion;

- (void)searchPhotosWithKeyword:(NSString *)keyword
                           page:(NSInteger)page
                  resultPerPage:(NSInteger)resultPerPage completion:(DZNHTTPRequestCompletion)completion;

- (void)cancelRequest;

@end
