//
//  MCRPhotoTag.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoTag.h"
#import "MCRPhotoServiceConstants.h"

@implementation MCRPhotoTag

+ (NSString *)name
{
    return NSStringFromClass([MCRPhotoTag class]);
}

+ (instancetype)photoTagFromService:(MCRPhotoPickerControllerService)service
{
    if (service != 0) {
        MCRPhotoTag *tag = [MCRPhotoTag new];
        tag.serviceName = [NSStringFromService(service) lowercaseString];
        return tag;
    }
    return nil;
}

+ (NSArray *)photoTagListFromService:(MCRPhotoPickerControllerService)service withResponse:(NSArray *)reponse
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:reponse.count];
    
    for (NSDictionary *object in reponse) {
        
        MCRPhotoTag *tag = [MCRPhotoTag photoTagFromService:service];
        tag.text = [object objectForKey:keyForSearchTagContent(service)];
        
        [result addObject:tag];
    }
    
    return result;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"serviceName = %@; content = %@;", self.serviceName, self.text];
}

@end
