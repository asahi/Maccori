//
//  MCRPhotoServiceConstants.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoServiceConstants.h"
#import "MCRPhotoMetadata.h"
#import "MCRPhotoTag.h"
#import "Private.h"

NSString *const MCRPhotoServiceClientConsumerKey = @"MCRPhotoServiceClientConsumerKey";
NSString *const MCRPhotoServiceClientConsumerSecret = @"MCRPhotoServiceClientConsumerSecret";

@implementation MCRPhotoServiceConstants
@end

NSString *NSUserDefaultsUniqueKey(NSUInteger type, NSString *key)
{
    return [NSString stringWithFormat:@"%@_%@", NSStringFromService(type), key];
}

NSURL *baseURLForService(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:              return [NSURL URLWithString:@"https://api.500px.com/v1"];
        case MCRPhotoPickerControllerServiceShutterstock:       return [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@@api.shutterstock.com/", kShutterStockAPIUserName, kShutterStockAPIKey]];
        case MCRPhotoPickerControllerServiceFlickr:             return [NSURL URLWithString:@"http://api.flickr.com/services/rest/"];
        default:                                                return nil;
    }
}

NSString *tagsResourceKeyPathForService(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:
        case MCRPhotoPickerControllerServiceShutterstock:
        case MCRPhotoPickerControllerServiceFlickr:
            return @"tags.tag";
        default:
            return nil;
    }
}

NSString *tagSearchUrlPathForService(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerServiceFlickr:             return @"flickr.tags.getRelated";
        default:                                                return nil;
    }
}

NSString *photosResourceKeyPathForService(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:              return @"photos";
        case MCRPhotoPickerControllerServiceShutterstock:       return @"results";
        case MCRPhotoPickerControllerServiceFlickr:             return @"photos.photo";
        default:                                                return nil;
    }
}

NSString *photoSearchUrlPathForService(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:              return @"photos/search";
        case MCRPhotoPickerControllerServiceShutterstock:       return @"images/search.json";
        case MCRPhotoPickerControllerServiceFlickr:             return @"flickr.photos.search";
        default:                                                return nil;
    }
}

NSString *keyForAPIConsumerKey(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:              return @"consumer_key";
        case MCRPhotoPickerControllerServiceFlickr:             return @"api_key";
        default:                                                return nil;
    }
}

NSString *keyForSearchTerm(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:              return @"term";
        case MCRPhotoPickerControllerServiceShutterstock:       return @"searchterm";
        case MCRPhotoPickerControllerServiceFlickr:             return @"text";
        default:                                                return nil;
    }
}

NSString *keyForSearchTag(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:
        case MCRPhotoPickerControllerServiceShutterstock:
        case MCRPhotoPickerControllerServiceFlickr:             return @"tag";
        default:                                                return nil;
    }
}

NSString *keyForSearchResultPerPage(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:              return @"rpp";
        case MCRPhotoPickerControllerServiceShutterstock:       return @"page_size";
        case MCRPhotoPickerControllerServiceFlickr:             return @"per_page";
        default:                                                return nil;
    }
}

NSString *keyForSearchTagContent(MCRPhotoPickerControllerService service)
{
    switch (service) {
        case MCRPhotoPickerControllerService500px:
        case MCRPhotoPickerControllerServiceFlickr:             return @"_content";
        default:                                                return nil;
    }
}

NSString *keyPathForObjectName(MCRPhotoPickerControllerService service, NSString *objectName)
{
    if ([objectName isEqualToString:[MCRPhotoTag name]]) {
        return tagsResourceKeyPathForService(service);
    }
    else if ([objectName isEqualToString:[MCRPhotoMetadata name]]) {
        return photosResourceKeyPathForService(service);
    }
    return nil;
}