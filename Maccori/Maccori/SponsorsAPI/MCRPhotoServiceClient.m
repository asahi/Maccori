//
//  MCRPhotoServiceClient.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoServiceClient.h"

#import "MCRPhotoServiceConstants.h"
#import "MCRPhotoMetadata.h"
#import "MCRPhotoTag.h"

@interface MCRPhotoServiceClient ()
@property (nonatomic, copy) DZNHTTPRequestCompletion completion;
@property (nonatomic, copy) NSString *loadingPath;
@end

@implementation MCRPhotoServiceClient
@synthesize service = _service;
@synthesize loading = _loading;

- (instancetype)initWithService:(MCRPhotoPickerControllerService)service
{
    self = [super initWithBaseURL:baseURLForService(service)];
    if (self) {
        self.parameterEncoding = AFJSONParameterEncoding;
        _service = service;
    }
    return self;
}


#pragma mark - Getter methods

- (BOOL)loading
{
    return (_loadingPath) ? YES : NO;
}

- (NSString *)consumerKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:NSUserDefaultsUniqueKey(_service, MCRPhotoServiceClientConsumerKey)];
}

- (NSString *)consumerSecret
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:NSUserDefaultsUniqueKey(_service, MCRPhotoServiceClientConsumerSecret)];
}

- (NSDictionary *)tagsParamsWithKeyword:(NSString *)keyword
{
    NSAssert(keyword, @"\"keyword\" cannot be nil for %@", NSStringFromService(_service));
    NSAssert([self consumerKey], @"\"consumerKey\" cannot be nil for %@", NSStringFromService(_service));
    NSAssert([self consumerSecret], @"\"consumerSecret\" cannot be nil for %@", NSStringFromService(_service));
    
    
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:[self consumerKey] forKey:keyForAPIConsumerKey(_service)];
    [params setObject:keyword forKey:keyForSearchTag(_service)];
    
    if (_service == MCRPhotoPickerControllerServiceFlickr) {
        [params setObject:tagSearchUrlPathForService(_service) forKey:@"method"];
        [params setObject:@"json" forKey:@"format"];
    }
    
    return params;
}

- (NSDictionary *)photosParamsWithKeyword:(NSString *)keyword page:(NSInteger)page resultPerPage:(NSInteger)resultPerPage
{
    NSAssert([self consumerKey], @"\"consumerKey\" cannot be nil for %@", NSStringFromService(_service));
    NSAssert([self consumerSecret], @"\"consumerSecret\" cannot be nil for %@", NSStringFromService(_service));

    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setObject:[self consumerKey] forKey:keyForAPIConsumerKey(_service)];
    [params setObject:keyword forKey:keyForSearchTerm(_service)];
    [params setObject:@(resultPerPage) forKey:keyForSearchResultPerPage(_service)];

    if (_service == MCRPhotoPickerControllerService500px || _service == MCRPhotoPickerControllerServiceFlickr) {
        [params setObject:@(page) forKey:@"page"];
    }
    if (_service == MCRPhotoPickerControllerService500px)
    {
        [params setObject:@[@(2),@(4)] forKey:@"image_size"];
    }
    else if (_service == MCRPhotoPickerControllerServiceFlickr)
    {
        [params setObject:photoSearchUrlPathForService(_service) forKey:@"method"];
        [params setObject:@"json" forKey:@"format"];
        [params setObject:@"photos" forKey:@"media"];
        [params setObject:@(YES) forKey:@"in_gallery"];
        [params setObject:@(1) forKey:@"safe_search"];
        [params setObject:@(1) forKey:@"content_type"];
    }
    return params;
}

- (NSData *)processData:(NSData *)data
{
    if (_service == MCRPhotoPickerControllerServiceFlickr) {
        
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *responsePrefix = @"jsonFlickrApi(";
        
        if ([string rangeOfString:responsePrefix].location != NSNotFound) {
            string = [[string stringByReplacingOccurrencesOfString:responsePrefix withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
            return [string dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    return data;
}

- (NSArray *)objectListForObject:(NSString *)objectName withJSON:(NSDictionary *)json
{
    NSString *keyPath = keyPathForObjectName(_service, objectName);
    NSMutableArray *objects = [NSMutableArray arrayWithArray:[json valueForKeyPath:keyPath]];
    
    if ([objectName isEqualToString:[MCRPhotoTag name]]) {
        
        if (_service == MCRPhotoPickerControllerServiceFlickr) {
            NSString *keyword = [json valueForKeyPath:@"tags.source"];
            if (keyword) [objects insertObject:@{keyForSearchTagContent(_service):keyword} atIndex:0];
        }
        
        return [MCRPhotoTag photoTagListFromService:_service withResponse:objects];
    }
    else if ([objectName isEqualToString:[MCRPhotoMetadata name]]) {
        return [MCRPhotoMetadata photoMetadataListFromService:_service withResponse:objects];
    }
    
    return nil;
}


#pragma mark - MCRPhotoServiceClient methods

- (void)searchTagsWithKeyword:(NSString *)keyword completion:(DZNHTTPRequestCompletion)completion
{
    _loadingPath = tagSearchUrlPathForService(_service);

    NSDictionary *params = [self tagsParamsWithKeyword:keyword];
    [self getObject:[MCRPhotoTag name] path:_loadingPath params:params completion:completion];
}

- (void)searchPhotosWithKeyword:(NSString *)keyword page:(NSInteger)page resultPerPage:(NSInteger)resultPerPage completion:(DZNHTTPRequestCompletion)completion
{
    _loadingPath = photoSearchUrlPathForService(_service);

    NSDictionary *params = [self photosParamsWithKeyword:keyword page:page resultPerPage:resultPerPage];
    [self getObject:[MCRPhotoMetadata name] path:_loadingPath params:params completion:completion];
}

- (void)getObject:(NSString *)objectName path:(NSString *)path params:(NSDictionary *)params completion:(DZNHTTPRequestCompletion)completion
{
    NSLog(@"%s\nobjectName : %@ \npath : %@\nparams: %@\n\n",__FUNCTION__, objectName, path, params);

    if (_service == MCRPhotoPickerControllerServiceFlickr) {
        path = @"";
    }
    [self getPath:path parameters:params success:^(AFHTTPRequestOperation *operation, id response) {
        
        NSData *data = [self processData:response];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments error:nil];
        
        if (completion) completion([self objectListForObject:objectName withJSON:json], nil);
        _loadingPath = nil;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (completion) completion(nil, error);
        _loadingPath = nil;
    }];
}

- (void)cancelRequest
{
    if (_loadingPath) {
        
        if (_service == MCRPhotoPickerControllerServiceFlickr) _loadingPath = @"";
        [self cancelAllHTTPOperationsWithMethod:@"GET" path:_loadingPath];
        
        _loadingPath = nil;
    }
}

@end
