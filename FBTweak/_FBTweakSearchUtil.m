/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "_FBTweakSearchUtil.h"
#import "_FBTweakArrayViewController.h"
#import "_FBTweakDictionaryViewController.h"
#import "_FBTweakColorViewController.h"
#import "FBTweakCategory.h"
#import "FBTweakCollection.h"

@implementation _FBTweakSearchUtil

+ (void)handleTweakSelection:(FBTweak *)tweak
                 inTableView:(UITableView *)tableView
                 atIndexPath:(NSIndexPath *)indexPath
        navigationController:(UINavigationController *)navigationController
{
    if ([tweak.possibleValues isKindOfClass:[NSDictionary class]]) {
        _FBTweakDictionaryViewController *vc = [[_FBTweakDictionaryViewController alloc] initWithTweak:tweak];
        [navigationController pushViewController:vc animated:YES];
    } else if ([tweak.possibleValues isKindOfClass:[NSArray class]]) {
        _FBTweakArrayViewController *vc = [[_FBTweakArrayViewController alloc] initWithTweak:tweak];
        [navigationController pushViewController:vc animated:YES];
    } else if ([tweak.defaultValue isKindOfClass:[UIColor class]]) {
        _FBTweakColorViewController *vc = [[_FBTweakColorViewController alloc] initWithTweak:tweak];
        [navigationController pushViewController:vc animated:YES];
    } else if (tweak.isAction) {
        dispatch_block_t block = tweak.defaultValue;
        if (block != NULL) {
            block();
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

+ (NSArray *)filteredCollectionsInCategories:(NSArray *)categories forQuery:(NSString *)searchQuery
{
    NSMutableArray *collections = [NSMutableArray array];
    
    for (FBTweakCategory *category in categories) {
        for (FBTweakCollection *collection in category.tweakCollections) {
            NSString *name = collection.name;
            if (categories.count > 1) {
                name = [NSString stringWithFormat:@"%@ / %@", category.name, collection.name];
            }
            FBTweakCollection *filteredCollection = [[FBTweakCollection alloc] initWithName:name];
            
            if ([self matches:collection.name searchQuery:searchQuery]) {
                for (FBTweak *tweak in collection.tweaks) {
                    [filteredCollection addTweak:tweak];
                }
            } else {
                for (FBTweak *tweak in collection.tweaks) {
                    if ([self matches:tweak.name searchQuery:searchQuery]) {
                        [filteredCollection addTweak:tweak];
                    }
                }
            }
            
            if (filteredCollection.tweaks.count > 0) {
                [collections addObject:filteredCollection];
            }
        }
    }
    
    return [collections copy];
}

+ (BOOL)matches:(NSString *)input searchQuery:(NSString *)searchQuery {
    if (@available(iOS 9.0, *)) {
        return [input localizedStandardContainsString:searchQuery];
    } else {
        return [input rangeOfString:searchQuery options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch].location != NSNotFound;
    }
}

@end
