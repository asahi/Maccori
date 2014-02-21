//
//  MCRPhotoServiceFactory.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoServiceFactory.h"
#import "MCRPhotoServiceClient.h"
#import "MCRPhotoServiceConstants.h"

@interface MCRPhotoServiceFactory ()
@property (nonatomic, strong) NSMutableArray *clients;
@end

@implementation MCRPhotoServiceFactory

+ (instancetype)defaultFactory
{
    static MCRPhotoServiceFactory *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [MCRPhotoServiceFactory new];
        _sharedInstance.clients = [NSMutableArray new];
    });
    return _sharedInstance;
}


#pragma mark - Getter methods

- (id<MCRPhotoServiceClientProtocol>)clientForService:(MCRPhotoPickerControllerService)service
{
    for (MCRPhotoServiceClient *client in self.clients) {
        if (client.service == service) {
            return client;
        }
    }
    MCRPhotoServiceClient *client = [[MCRPhotoServiceClient alloc] initWithService:service];
    [self.clients addObject:client];
    
    return client;
}


#pragma mark - Setter methods

+ (void)setConsumerKey:(NSString *)key consumerSecret:(NSString *)secret service:(MCRPhotoPickerControllerService)service
{
    [[NSUserDefaults standardUserDefaults] setObject:key forKey:NSUserDefaultsUniqueKey(service, MCRPhotoServiceClientConsumerKey)];
    [[NSUserDefaults standardUserDefaults] setObject:secret forKey:NSUserDefaultsUniqueKey(service, MCRPhotoServiceClientConsumerSecret)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - MCRPhotoServiceFactory methods

- (void)reset
{
    for (id<MCRPhotoServiceClientProtocol> client in _clients) {
        [client cancelRequest];
    }
    
    _clients = nil;
    _clients = [NSMutableArray new];
}

@end
