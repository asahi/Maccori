//
//  MCRPhotoDisplayController.m
//  MCRPhotoPickerController
//
//  Created by 鄭 基旭 on 2014/02/22.
//  Copyright (c) 2014年 mixi.inc. All rights reserved.
//

#import "MCRPhotoDisplayViewController.h"
#import "MCRPhotoPickerController.h"

#import "MCRPhotoDisplayViewCell.h"
#import "MCRPhotoMetadata.h"
#import "MCRPhotoTag.h"

#import "MCRPhotoServiceFactory.h"

#define  kMCRPhotoMinimumBarHeight 44.0

static NSString *kThumbCellID = @"kThumbCellID";
static NSString *kThumbFooterID = @"kThumbFooterID";
static NSString *kTagCellID = @"kTagCellID";

@interface MCRPhotoDisplayViewController () <UISearchDisplayDelegate, UISearchBarDelegate,
UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, readwrite) UIButton *loadButton;
@property (nonatomic, readwrite) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) NSMutableArray *photoMetadatas;
@property (nonatomic, strong) NSMutableArray *photoTags;
@property (nonatomic, strong) NSArray *segmentedControlTitles;
@property (nonatomic) MCRPhotoPickerControllerService selectedService;
@property (nonatomic) MCRPhotoPickerControllerService previousService;
@property (nonatomic) NSInteger resultPerPage;
@property (nonatomic) NSInteger currentPage;

@end

@implementation MCRPhotoDisplayViewController

- (instancetype)init
{
    return [self initWithCollectionViewLayout:[MCRPhotoDisplayViewController flowLayout]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithCollectionViewLayout:layout];
    if (self) {
        self.title = @"Photos";
    }
    return self;
}


#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];

    _currentPage = 1;
    _columnCount = 4;

    _segmentedControlTitles = NSArrayFromServices(self.navigationController.supportedServices);
    _selectedService = MCRFirstPhotoServiceFromPhotoServices(self.navigationController.supportedServices);

    self.view.backgroundColor = [UIColor whiteColor];

    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.automaticallyAdjustsScrollViewInsets = YES;

    self.collectionView.backgroundView = [UIView new];
    self.collectionView.backgroundView.backgroundColor = [UIColor whiteColor];
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight;
    self.collectionView.contentInset = UIEdgeInsetsMake(self.searchBar.frame.size.height+8.0, 0, 0, 0);
    self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.searchBar.frame.size.height, 0, 0, 0);

    [self.collectionView registerClass:[MCRPhotoDisplayViewCell class] forCellWithReuseIdentifier:kThumbCellID];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kThumbFooterID];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    _searchController.searchResultsTableView.backgroundColor = [UIColor whiteColor];
    _searchController.searchResultsTableView.tableHeaderView = [UIView new];
    _searchController.searchResultsTableView.tableFooterView = [UIView new];
    _searchController.searchResultsTableView.backgroundView = [UIView new];
    _searchController.searchResultsTableView.backgroundView.backgroundColor = [UIColor whiteColor];
    _searchController.searchResultsTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    _searchController.searchResultsDataSource = self;
    _searchController.searchResultsDelegate = self;
    _searchController.delegate = self;

    [_searchController.searchResultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kTagCellID];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (!_photoMetadatas) {
        _photoMetadatas = [NSMutableArray new];

        if (_searchTerm.length == 0) {
            [self.searchController setActive:YES];
            [_searchBar becomeFirstResponder];
        }
        else [self searchPhotosWithKeyword:_searchTerm];
    }
}

#pragma mark - Getter methods

+ (UICollectionViewFlowLayout *)flowLayout
{
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 2.0;
    flowLayout.minimumInteritemSpacing = 0.0;
    return flowLayout;
}

- (MCRPhotoPickerController *)navigationController
{
    return (MCRPhotoPickerController *)[super navigationController];
}

- (UISearchBar *)searchBar
{
    if (!_searchBar)
    {
        _searchBar = [[UISearchBar alloc] initWithFrame:[self searchBarFrame]];
        _searchBar.placeholder = @"Search";
        _searchBar.barStyle = UIBarStyleDefault;
        _searchBar.searchBarStyle = UISearchBarStyleProminent;
        _searchBar.backgroundColor = [UIColor blueColor];
        _searchBar.barTintColor = [UIColor colorWithRed:202.0/255.0 green:202.0/255.0 blue:207.0/255.0 alpha:1.0];
        _searchBar.tintColor = self.view.window.tintColor;
        _searchBar.keyboardType = UIKeyboardAppearanceDark;
        _searchBar.text = _searchTerm;
        _searchBar.delegate = self;

        _searchBar.scopeButtonTitles = [self segmentedControlTitles];
        _searchBar.selectedScopeButtonIndex = 0;

        [self.view addSubview:_searchBar];
    }
    return _searchBar;
}

- (UIButton *)loadButton
{
    if (!_loadButton)
    {
        _loadButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_loadButton setTitle:@"Load More" forState:UIControlStateNormal];
        [_loadButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
        [_loadButton addTarget:self action:@selector(downloadData) forControlEvents:UIControlEventTouchUpInside];
        [_loadButton.titleLabel setFont:[UIFont systemFontOfSize:17.0]];
        [_loadButton setBackgroundColor:[UIColor redColor]];

        [_loadButton addSubview:self.activityIndicator];
    }
    return _loadButton;
}

- (UIActivityIndicatorView *)activityIndicator
{
    if (!_activityIndicator)
    {
        _activityIndicator = [[UIActivityIndicatorView alloc] init];
        _activityIndicator.hidesWhenStopped = YES;
        _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    }
    return _activityIndicator;
}

- (CGSize)cellSize
{
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    CGFloat size = (self.navigationController.view.bounds.size.width/_columnCount) - flowLayout.minimumLineSpacing;
    return CGSizeMake(size, size);
}

- (CGSize)footerSize
{
    return CGSizeMake(0, (self.navigationController.view.frame.size.height > 480.0) ? 60.0 : 50.0);
}

- (CGSize)topBarsSize
{
    CGFloat statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navigationHeight = self.navigationController.navigationBar.frame.size.height;
    CGFloat topBarsHeight = navigationHeight + statusHeight;
    topBarsHeight += self.searchBar.frame.size.height+8.0;

    return CGSizeMake(self.navigationController.view.frame.size.width, topBarsHeight);
}

- (CGSize)contentSize
{
    CGFloat viewHeight = self.navigationController.view.frame.size.height;
    CGFloat topBarsHeight = [self topBarsSize].height;
    return CGSizeMake(self.navigationController.view.frame.size.width, viewHeight-topBarsHeight);
}

- (CGRect)searchBarFrame
{
    BOOL shouldShift = _searchBar.showsScopeBar;

    CGFloat statusHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width,  kMCRPhotoMinimumBarHeight);
    frame.size.height = shouldShift ?  kMCRPhotoMinimumBarHeight*2 :  kMCRPhotoMinimumBarHeight;
    frame.origin.y = shouldShift ? statusHeight : 0.0;

    if (!shouldShift) {
        frame.origin.y += statusHeight+ kMCRPhotoMinimumBarHeight;
    }
    return frame;
}

- (NSInteger)rowCount
{
    CGSize contentSize = [self contentSize];
    CGFloat footerSize = [self footerSize].height;
    contentSize.height -= footerSize;
    contentSize.height += self.navigationController.navigationBar.frame.size.height;

    CGFloat cellHeight = [self cellSize].height;

    NSInteger count = (int)(contentSize.height/cellHeight);
    return count;
}


- (NSInteger)resultPerPage
{
    return self.columnCount * self.rowCount;
}

- (BOOL)shouldShowFooter
{
    return (_photoMetadatas.count%self.resultPerPage == 0) ? YES : NO;
}


#pragma mark - Setter methods

- (void)setSearchBarText:(NSString *)text
{
    self.searchController.searchBar.text = text;
}


- (void)setPhotoSearchList:(NSArray *)list
{
    [self showActivityIndicators:NO];

    [_photoMetadatas addObjectsFromArray:list];
    [self.collectionView reloadData];

    CGSize contentSize = self.collectionView.contentSize;
    self.collectionView.contentSize = CGSizeMake(contentSize.width, contentSize.height+[self footerSize].height);
}


- (void)setTagSearchList:(NSArray *)list
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    if (!_photoTags) _photoTags = [NSMutableArray new];
    else [_photoTags removeAllObjects];

    [_photoTags addObjectsFromArray:list];

    if (_photoTags.count == 0) {

        MCRPhotoTag *tag = [MCRPhotoTag photoTagFromService:_selectedService];
        tag.text = _searchBar.text;
        [_photoTags addObject:tag];
    }

    [_searchController.searchResultsTableView reloadData];
}


- (void)setSearchError:(NSError *)error
{
    [self showActivityIndicators:NO];

    if (error.code == NSURLErrorCancelled || error.code == NSURLErrorUnknown) {
        return;
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:error.localizedDescription
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles: nil];
    [alert show];

    NSLog(@"error : %@", error);
}


#pragma mark - MCRPhotoDisplayController methods


- (void)showActivityIndicators:(BOOL)visible
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = visible;

    if (visible) {
        [self.activityIndicator startAnimating];
        [_loadButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    }
    else {
        [self.activityIndicator stopAnimating];
    }

    _loading = visible;
    self.collectionView.userInteractionEnabled = !visible;
}


- (void)handleSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    MCRPhotoMetadata *metadata = [_photoMetadatas objectAtIndex:indexPath.row];

    if (self.navigationController.allowsEditing) {
        MCRPhotoEditViewController *photoEditViewController = [[MCRPhotoEditViewController alloc] initWithPhotoMetadata:metadata cropMode:self.navigationController.editingMode];
        [self.navigationController pushViewController:photoEditViewController animated:YES];
    }
    else {
        [self showActivityIndicators:YES];
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:metadata.sourceURL
                                                              options:SDWebImageCacheMemoryOnly|SDWebImageRetryFailed
                                                             progress:NULL
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished){
                                                                if (image) {
                                                                    [MCRPhotoEditViewController didFinishPickingOriginalImage:image editedImage:nil
                                                                                                                     cropRect:CGRectZero
                                                                                                                     cropMode:MCRPhotoEditViewControllerCropModeNone
                                                                                                                photoMetadata:metadata];
                                                                }
                                                                else {
                                                                    [self setSearchError:error];
                                                                }
                                                                [self showActivityIndicators:NO];
                                                            }];
    }
    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (BOOL)canSearchTag:(NSString *)term
{
    if ([_searchController.searchBar isFirstResponder] && term.length > 2) {
        [self searchTags:term];
        return YES;
    }
    else {
        [_photoTags removeAllObjects];
        [_searchController.searchResultsTableView reloadData];
        return NO;
    }
}


- (void)searchTags:(NSString *)keyword
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    id<MCRPhotoServiceClientProtocol> client =  [[MCRPhotoServiceFactory defaultFactory] clientForService:MCRPhotoPickerControllerServiceFlickr];
    [client searchTagsWithKeyword:keyword completion:^(NSArray *list, NSError *error) {
        if (error) [self setSearchError:error];
        else [self setTagSearchList:list];
    }];
}

- (void)shouldSearchPhotos:(NSString *)keyword
{
    if ((_previousService != _selectedService || _searchTerm != keyword) && keyword.length > 1) {
        _previousService = _selectedService;
        [self resetPhotos];
        [self searchPhotosWithKeyword:keyword];
    }
}

- (void)searchPhotosWithKeyword:(NSString *)keyword
{
    [self showActivityIndicators:YES];
    _searchTerm = keyword;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    NSLog(@"Searching \"%@\" (page %d) on %@", keyword, _currentPage, NSStringFromService(_selectedService));
#pragma clang diagnostic pop

    id<MCRPhotoServiceClientProtocol> client =  [[MCRPhotoServiceFactory defaultFactory] clientForService:_selectedService];

    [client searchPhotosWithKeyword:keyword page:_currentPage resultPerPage:self.resultPerPage completion:^(NSArray *list, NSError *error) {
        if (error) [self setSearchError:error];
        else [self setPhotoSearchList:list];
    }];
}

- (void)stopLoadingRequest
{
    if (self.loading) {
        [self showActivityIndicators:NO];

        id<MCRPhotoServiceClientProtocol> client =  [[MCRPhotoServiceFactory defaultFactory] clientForService:_selectedService];
        [client cancelRequest];
    }

    //    for (MCRPhotoDisplayViewCell *cell in [self.collectionView visibleCells]) {
    //        [cell.imageView cancelCurrentImageLoad];
    //    }
}

- (void)downloadData
{
    _loadButton.enabled = NO;
    _currentPage++;
    [self searchPhotosWithKeyword:_searchTerm];
}

- (void)resetPhotos
{
    [_photoMetadatas removeAllObjects];
    _currentPage = 1;
    [self.collectionView reloadData];
}


#pragma mark - UICollectionViewDataSource methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _photoMetadatas.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MCRPhotoDisplayViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kThumbCellID forIndexPath:indexPath];
    cell.tag = indexPath.row;

    MCRPhotoMetadata *metadata = [_photoMetadatas objectAtIndex:indexPath.row];

    [cell.imageView cancelCurrentImageLoad];

    [cell.imageView setImageWithURL:metadata.thumbURL placeholderImage:nil
                            options:SDWebImageCacheMemoryOnly completed:NULL];

    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {

        UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                              withReuseIdentifier:kThumbFooterID
                                                                                     forIndexPath:indexPath];
        if ([self shouldShowFooter]) {
            if (!_loadButton && footer.subviews.count == 0) {
                [footer addSubview:self.loadButton];
            }
            _loadButton.frame = footer.bounds;

            if (_photoMetadatas.count > 0) {
                _loadButton.enabled = YES;
                [_loadButton setTitleColor:self.view.window.tintColor forState:UIControlStateNormal];

                self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
                [self.activityIndicator stopAnimating];
            }
            else {
                _loadButton.enabled = NO;
                [_loadButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];

                self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
                self.activityIndicator.color = [UIColor grayColor];
            }
        }
        else {
            [self.activityIndicator stopAnimating];
            [_loadButton removeFromSuperview];
            [self setLoadButton:nil];
        }
        return footer;
    }
    return nil;
}


#pragma mark - UICollectionViewDataDelegate methods

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    if ([[UIMenuController sharedMenuController] isMenuVisible]) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

    if ([_searchBar isFirstResponder]) {
        [_searchBar resignFirstResponder];
        [self performSelector:@selector(handleSelectionAtIndexPath:) withObject:indexPath afterDelay:0.3];
    }
    else [self handleSelectionAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIMenuController sharedMenuController] isMenuVisible]) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
{
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath;
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellSize];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (_photoMetadatas.count == 0) {
        return [self contentSize];
    }
    else return [self footerSize];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MCRPhotoDisplayViewCell *cell = (MCRPhotoDisplayViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

    if (cell.imageView.image) {
        return YES;
    }
    else return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (![NSStringFromSelector(action) isEqualToString:@"copy:"]) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if ([NSStringFromSelector(action) isEqualToString:@"copy:"]) {

        MCRPhotoDisplayViewCell *cell = (MCRPhotoDisplayViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

        UIImage *image = cell.imageView.image;
        if (image) [[UIPasteboard generalPasteboard] setImage:image];
    }
}


#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _photoTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTagCellID];

    MCRPhotoTag *tag = [_photoTags objectAtIndex:indexPath.row];

    if (_photoTags.count == 1) {
        cell.textLabel.text = [NSString stringWithFormat:@"Search for \"%@\"", tag.text];
    }
    else {
        cell.textLabel.text = tag.text;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  kMCRPhotoMinimumBarHeight;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MCRPhotoTag *tag = [_photoTags objectAtIndex:indexPath.row];

    [self shouldSearchPhotos:tag.text];
    [self.searchController setActive:NO animated:YES];
    [self setSearchBarText:tag.text];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UISearchDelegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [self stopLoadingRequest];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self stopLoadingRequest];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{

}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [_photoTags removeAllObjects];
}

- (void)searchBarShouldShift:(BOOL)shift
{
    _searchBar.showsScopeBar = shift;

    [UIView animateWithDuration:0.25
                     animations:^{
                         [self.searchBar setFrame:[self searchBarFrame]];
                         [self.searchController setActive:shift];
                     }
                     completion:NULL];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *text = searchBar.text;

    [self shouldSearchPhotos:text];
    [self searchBarShouldShift:NO];
    [self setSearchBarText:text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    NSString *text = searchBar.text;

    [self searchBarShouldShift:NO];
    [self setSearchBarText:text];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSString *name = [searchBar.scopeButtonTitles objectAtIndex:selectedScope];
    _selectedService = MCRPhotoServiceFromName(name);
}


#pragma mark - UISearchDisplayDelegate methods

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self searchBarShouldShift:YES];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{

}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self searchBarShouldShift:NO];

    [_photoTags removeAllObjects];
    [controller.searchResultsTableView reloadData];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{

}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    NSLog(@"%s",__FUNCTION__);
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    return [self canSearchTag:searchString];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UITableView *tableView = [self.searchController searchResultsTableView];
    [tableView setContentInset:UIEdgeInsetsZero];
    [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
}


#pragma mark - View lifeterm

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
