
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
#import "AFHTTPRequestOperation.h"

@interface MCRPhotoServiceClient ()
@property (nonatomic, copy) MCRHTTPSearchRequestCompletion completion;
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
    [params setObject:keyword forKey:keyForSearchTerm(_service)];
    [params setObject:@(resultPerPage) forKey:keyForSearchResultPerPage(_service)];

    if (_service == MCRPhotoPickerControllerService500px || _service == MCRPhotoPickerControllerServiceFlickr) {
        [params setObject:[self consumerKey] forKey:keyForAPIConsumerKey(_service)];
        [params setObject:@(page) forKey:@"page"];
    }
    else if (_service == MCRPhotoPickerControllerServiceShutterstock)
    {
        [params setObject:@(page) forKey:@"page_number"];
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
    NSData *convertedData = data;
    NSString *string = nil;
    if (_service == MCRPhotoPickerControllerServiceShutterstock) {
        string = [[NSString alloc] initWithData:convertedData encoding:NSUTF8StringEncoding];
        return  [string dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if (_service == MCRPhotoPickerControllerServiceFlickr) {
        
        NSString *string = [[NSString alloc] initWithData:convertedData encoding:NSUTF8StringEncoding];
        NSString *responsePrefix = @"jsonFlickrApi(";
        
        if ([string rangeOfString:responsePrefix].location != NSNotFound) {
            string = [[string stringByReplacingOccurrencesOfString:responsePrefix withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""];
            return [string dataUsingEncoding:NSUTF8StringEncoding];
        }
    }
    
    return convertedData;
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

- (void)searchTagsWithKeyword:(NSString *)keyword completion:(MCRHTTPSearchRequestCompletion)completion
{
    _loadingPath = tagSearchUrlPathForService(_service);

    NSDictionary *params = [self tagsParamsWithKeyword:keyword];
    [self getObject:[MCRPhotoTag name] path:_loadingPath params:params completion:completion];
}

- (void)searchPhotosWithKeyword:(NSString *)keyword page:(NSInteger)page resultPerPage:(NSInteger)resultPerPage completion:(MCRHTTPSearchRequestCompletion)completion
{
    _loadingPath = photoSearchUrlPathForService(_service);

    NSDictionary *params = [self photosParamsWithKeyword:keyword page:page resultPerPage:resultPerPage];
    [self getObject:[MCRPhotoMetadata name] path:_loadingPath params:params completion:completion];
}

- (void)getObject:(NSString *)objectName path:(NSString *)path params:(NSDictionary *)params completion:(MCRHTTPSearchRequestCompletion)completion
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

- (void)postPhoto:(UIImage *)image completion:(MCRHTTPImageRequestCompletion)completion;
{
    NSData* imageToUpload = UIImageJPEGRepresentation( image, 1.0 );
    if (imageToUpload)
    {
        NSDictionary *parameters = @{ @"partner_username":@"kim", @"partner_apikey" : @"7t2PqFYpb2qC9QD2cIrXJ6yNvnwKzI9c" };

        MCRPhotoServiceClient *client= [self initWithBaseURL:baseURLForService(MCRPhotoPickerControllerServiceFlashFoto)];
        NSString *path = [NSString stringWithFormat:@"add/?partner_username=%@&partner_apikey=%@", kFlashFotoAPIUsername, kFlashFotoAPIKey];
        NSMutableURLRequest *request = [client multipartFormRequestWithMethod:@"POST"
                                                                         path:path
                                                                   parameters:parameters
                                                    constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
            [formData appendPartWithFileData: imageToUpload name:@"image" fileName:@"test.jpeg" mimeType:@"image/jpeg"];
        }];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation  alloc] initWithRequest:request];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation
                                                   , id responseObject) {
            NSData *data = [self processData:responseObject];
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments error:nil];
            if (completion) {
                completion([json objectForKey:@"Image"] , [json objectForKey:@"ImageVersion"] , nil);
            }

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            // code
        }
         ];
        [operation start];
    }

//
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    NSDictionary *parameters = @{@"foo": @"bar"};
//    NSURL *filePath = [NSURL fileURLWithPath:@"file://path/to/image.png"];
//    [manager POST:@"http://example.com/resources.json" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
//        [formData appendPartWithFileData:imageData name:@"image" error:nil];
//    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"Success: %@", responseObject);
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
//
//    NSDictionary *params = @{
//                             @"partner_username":@"kim",
//                             @"partner_apikey" : @"7t2PqFYpb2qC9QD2cIrXJ6yNvnwKzI9c",
//                             @"Content-type":@"image/jpeg",
//                             @"body": imageToUpload
//                             };

//    [self postPath:@"add" parameters:params success:^(AFHTTPRequestOperation *operation, id response) {
//
//        NSData *data = [self processData:response];
//        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments error:nil];
//
//        if (completion) {
////            completion(nil, nil);
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
////        if (completion) completion(nil, error);
//    }];
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

