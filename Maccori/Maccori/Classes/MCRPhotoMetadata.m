//
//  MCRPhotoMetadata.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoMetadata.h"

@implementation MCRPhotoMetadata

+ (NSString *)name
{
    return NSStringFromClass([MCRPhotoMetadata class]);
}

+ (instancetype)photoMetadataFromService:(MCRPhotoPickerControllerService)service
{
    if (service != 0) {
        MCRPhotoMetadata *metadata = [MCRPhotoMetadata new];
        metadata.serviceName = [NSStringFromService(service) lowercaseString];
        return metadata;
    }
    return nil;
}

+ (NSArray *)photoMetadataListFromService:(MCRPhotoPickerControllerService)service withResponse:(NSArray *)reponse
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:reponse.count];

    for (NSDictionary *object in reponse) {

        MCRPhotoMetadata *metadata = [MCRPhotoMetadata photoMetadataFromService:service];

        if ((service & MCRPhotoPickerControllerService500px) > 0)
        {
            metadata.id = [object valueForKey:@"id"];
            metadata.authorName = [[object valueForKeyPath:@"user.fullname"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            metadata.authorUsername = [object valueForKeyPath:@"user.username"];
            metadata.authorProfileURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://500px.com/%@", metadata.authorUsername]];
            metadata.detailURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://500px.com/photo/%@", metadata.Id]];

            metadata.thumbURL = [NSURL URLWithString:[[[object objectForKey:@"images"] objectAtIndex:0] objectForKey:@"url"]];
            metadata.sourceURL = [NSURL URLWithString:[[[object objectForKey:@"images"] objectAtIndex:1] objectForKey:@"url"]];
        }
        else if ((service & MCRPhotoPickerControllerServiceFlickr) > 0)
        {
            metadata.id = [object objectForKey:@"id"];
            metadata.authorName = nil;
            metadata.authorUsername = [object objectForKey:@"owner"];
            metadata.authorProfileURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.flickr.com/photos/%@", metadata.authorUsername]];
            metadata.detailURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.flickr.com/photos/%@/%@", metadata.authorUsername, metadata.Id]];

            NSMutableString *url = [NSMutableString stringWithFormat:@"http://farm%@.static.flickr.com/%@/%@_%@", [[object objectForKey:@"farm"] stringValue], [object objectForKey:@"server"], [object objectForKey:@"id"], [object objectForKey:@"secret"]];
            metadata.thumbURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@_q.jpg", url]];
            metadata.sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@_b.jpg", url]];
        }
        [result addObject:metadata];
    }

    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"serviceName = %@; id = %@; authorName = %@; authorUsername = %@; authorProfileURL = %@; detailURL = %@; thumbURL = %@; sourceURL = %@;", self.serviceName, self.Id, self.authorName, self.authorUsername, self.authorProfileURL, self.detailURL, self.thumbURL, self.sourceURL];
}

@end
