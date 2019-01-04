/**
 Copyright (c) 2014-present, Facebook, Inc.
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBTweakCollection.h"
#import "FBTweakCategory.h"
#import "FBTweak.h"
#import "_FBTweakSearchUtil.h"
#import "_FBTweakCollectionViewController.h"
#import "_FBTweakTableViewCell.h"
#import "_FBKeyboardManager.h"

@interface _FBTweakCollectionViewController () <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, UISearchResultsUpdating>
@end

@implementation _FBTweakCollectionViewController {
    UITableView *_tableView;
    UISearchBar *_searchBar;
    UISearchController *_searchController;

    NSArray *_sortedCollections;
    _FBKeyboardManager *_keyboardManager;
}

- (instancetype)initWithTweakCategory:(FBTweakCategory *)category
{
    if ((self = [super init])) {
        _tweakCategory = category;
        self.title = _tweakCategory.name;
        [self _reloadData];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.view addSubview:_tableView];
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.searchBar.placeholder = @"Search Tweaks";
    self.definesPresentationContext = YES;
    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
    } else {
        _tableView.tableHeaderView = _searchController.searchBar;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_done)];
    
    _keyboardManager = [[_FBKeyboardManager alloc] initWithViewScrollView:_tableView];
}

- (void)dealloc
{
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:animated];
    [self _reloadData];
    
    [_keyboardManager enable];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_keyboardManager disable];
}

- (void)_reloadData
{
    _sortedCollections = [_tweakCategory.tweakCollections sortedArrayUsingComparator:^(FBTweakCollection *a, FBTweakCollection *b) {
        return [a.name localizedStandardCompare:b.name];
    }];
    [_tableView reloadData];
}

- (void)_done
{
    [_delegate tweakCollectionViewControllerSelectedDone:self];
}

- (NSArray *)collectionsToDisplay {
    if (self.isFiltering) {
        NSString *query = _searchController.searchBar.text;
        return [_FBTweakSearchUtil filteredCollectionsInCategories:@[self.tweakCategory] forQuery:query];;
    } else {
        return _sortedCollections;
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self collectionsToDisplay].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    FBTweakCollection *collection = [self collectionsToDisplay][section];
    return collection.tweaks.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    FBTweakCollection *collection = [self collectionsToDisplay][section];
    return collection.name;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *_FBTweakCollectionViewControllerCellIdentifier = @"_FBTweakCollectionViewControllerCellIdentifier";
    _FBTweakTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_FBTweakCollectionViewControllerCellIdentifier];
    if (cell == nil) {
        cell = [[_FBTweakTableViewCell alloc] initWithReuseIdentifier:_FBTweakCollectionViewControllerCellIdentifier];
    }
    
    FBTweakCollection *collection = [self collectionsToDisplay][indexPath.section];
    FBTweak *tweak = collection.tweaks[indexPath.row];
    cell.tweak = tweak;
    cell.searchQuery = _searchBar.text;
    
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FBTweakCollection *collection = [self collectionsToDisplay][indexPath.section];
    FBTweak *tweak = collection.tweaks[indexPath.row];
    [_FBTweakSearchUtil handleTweakSelection:tweak inTableView:tableView atIndexPath:indexPath navigationController:self.navigationController];
}

#pragma mark UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    [_tableView reloadData];
}

- (BOOL)isFiltering {
    return _searchController.isActive && _searchController.searchBar.text.length > 0;
}

@end
