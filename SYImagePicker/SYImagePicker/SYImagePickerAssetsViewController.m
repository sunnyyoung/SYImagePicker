//
//  SYImagePickerAssetsViewController.m
//  ShareJobStudent
//
//  Created by Sunnyyoung on 15/11/5.
//  Copyright © 2015年 GeekBean Technology Co., Ltd. All rights reserved.
//

#import "SYImagePickerAssetsViewController.h"
#import "SYImagePickerViewController.h"
#import "SYImagePickerBrowserViewController.h"
#import "SYImagePickerAssetsCell.h"
#import "SYImagePickerSelectButton.h"

@interface SYImagePickerAssetsViewController () <UICollectionViewDelegateFlowLayout, SYImagePickerAssetsCellDelegate, SYImagePickerBrowserViewControllerDelegate>

@property (nonatomic, strong) UIBarButtonItem *previewBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *doneBarButtonItem;

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@property (nonatomic, strong) NSMutableArray *assetsArray;
@property (nonatomic, strong) NSMutableArray *selectedAssetsArray;

@end

@implementation SYImagePickerAssetsViewController

#pragma mark - LifeCycle

- (instancetype)init {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setMinimumInteritemSpacing:1.0];
    [flowLayout setMinimumLineSpacing:1.0];
    self = [super initWithCollectionViewLayout:flowLayout];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title assetsGroupURL:(NSURL *)assetsGroupURL {
    self = [self init];
    if (self) {
        [self setTitle:title];
        [self loadAssetsWithAssetsGroupURL:assetsGroupURL];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setup {
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction)]];
    UIBarButtonItem *flexibleBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self setToolbarItems:@[self.previewBarButtonItem, flexibleBarButtonItem, self.doneBarButtonItem]];
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
    [self.collectionView registerClass:[SYImagePickerAssetsCell class] forCellWithReuseIdentifier:AssetsCell];
}

#pragma mark - CollectionView FlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = (CGRectGetWidth([UIScreen mainScreen].bounds) - 5) / 4.0;
    return CGSizeMake(width, width);
}

#pragma mark - CollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.assetsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SYImagePickerAssetsCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AssetsCell forIndexPath:indexPath];
    ALAsset *asset = self.assetsArray[indexPath.row];
    cell.asset = asset;
    cell.selectedIndex = [self indexOfSelectedAsset:asset];
    cell.indexPath = indexPath;
    cell.delegate = self;
    return cell;
}

#pragma mark - CollectionView Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    SYImagePickerBrowserViewController *browserViewController = [[SYImagePickerBrowserViewController alloc] initWithAssetsArray:self.assetsArray currentIndex:indexPath.row];
    browserViewController.delegate = self;
    [self.navigationController pushViewController:browserViewController animated:YES];
}

#pragma mark - ImagePickerAssetsCell Delegate

- (void)didSelectAssetsCell:(SYImagePickerAssetsCell *)assetsCell {
    ALAsset *asset = self.assetsArray[assetsCell.indexPath.row];
    [self selectAsset:asset];
    [assetsCell setSelectedIndex:[self indexOfSelectedAsset:asset]];
}

- (void)didDeselectAssetsCell:(SYImagePickerAssetsCell *)assetsCell {
    ALAsset *asset = self.assetsArray[assetsCell.indexPath.row];
    [self deselectAsset:asset];
    [assetsCell setSelectedIndex:0];
}

#pragma mark - ImagePickerBrowserViewController Delegate

- (NSUInteger)numberOfSelectedAssetsInBrowserViewController:(SYImagePickerBrowserViewController *)browserViewController {
    return self.selectedAssetsArray.count;
}

- (NSUInteger)browserViewController:(SYImagePickerBrowserViewController *)browserViewController selectedIndexOfAsset:(ALAsset *)asset {
    return [self indexOfSelectedAsset:asset];
}

- (void)browserViewController:(SYImagePickerBrowserViewController *)browserViewController selectAsset:(ALAsset *)asset {
    [self selectAsset:asset];
}

- (void)browserViewController:(SYImagePickerBrowserViewController *)browserViewController deselectAsset:(ALAsset *)asset {
    [self deselectAsset:asset];
    [self.collectionView reloadData];
}

- (void)browserViewController:(SYImagePickerBrowserViewController *)browserViewController didFinishSelectAsset:(ALAsset *)asset {
    [self doneAction];
}

#pragma mark - Event Response

- (void)previewAction {
    if (self.selectedAssetsArray.count == 0) {
        return;
    }
    SYImagePickerBrowserViewController *browserViewController = [[SYImagePickerBrowserViewController alloc] initWithAssetsArray:self.selectedAssetsArray currentIndex:0];
    browserViewController.delegate = self;
    [self.navigationController pushViewController:browserViewController animated:YES];
}

- (void)doneAction {
    if ([((SYImagePickerViewController *)self.navigationController).imagePickerDelegate respondsToSelector:@selector(imagePickerViewController:didFinishSelectImages:thumbs:)]) {
        NSMutableArray *imageArray = [NSMutableArray array];
        NSMutableArray *thumbArray = [NSMutableArray array];
        for (ALAsset *asset in self.selectedAssetsArray) {
            @autoreleasepool {
                UIImage *thumb = [UIImage imageWithCGImage:asset.thumbnail];
                UIImage *image = [UIImage imageWithCGImage:[asset defaultRepresentation].fullScreenImage];
                [thumbArray addObject:thumb];
                [imageArray addObject:image];
            }
        }
        [((SYImagePickerViewController *)self.navigationController).imagePickerDelegate imagePickerViewController:(SYImagePickerViewController *)self.navigationController didFinishSelectImages:imageArray thumbs:thumbArray];
    }
}

- (void)cancelAction {
    if ([((SYImagePickerViewController *)self.navigationController).imagePickerDelegate respondsToSelector:@selector(imagePickerViewControllerDidCancel:)]) {
        [((SYImagePickerViewController *)self.navigationController).imagePickerDelegate imagePickerViewControllerDidCancel:(SYImagePickerViewController *)self.navigationController];
    }
}

#pragma mark - Load Assets

- (void)loadAssetsWithAssetsGroupURL:(NSURL *)assetsGroupURL {
    __weak typeof(self) weakSelf = self;
    [self.assetsLibrary groupForURL:assetsGroupURL resultBlock:^(ALAssetsGroup *assetsGroup){
        weakSelf.assetsGroup = assetsGroup;
        if (weakSelf.assetsGroup) {
            [weakSelf.assetsGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [weakSelf.assetsGroup enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if (result) {
                        [weakSelf.assetsArray insertObject:result atIndex:0];
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.collectionView reloadData];
                    NSInteger rows = [self.collectionView numberOfItemsInSection:0] - 1;
                    [weakSelf.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:rows inSection:0]
                                                    atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
                });
            });
        }
    } failureBlock:^(NSError *error){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"加载图片失败" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }];
}

#pragma mark - Select && Deselect Asset

- (BOOL)isSelectedAsset:(ALAsset *)anAsset {
    for (ALAsset *asset in self.selectedAssetsArray) {
        NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
        NSURL *anAssetURL = [anAsset valueForProperty:ALAssetPropertyAssetURL];
        if ([assetURL.absoluteString isEqualToString:anAssetURL.absoluteString]) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)indexOfSelectedAsset:(ALAsset *)asset {
    if ([self isSelectedAsset:asset]) {
        return [self.selectedAssetsArray indexOfObject:asset] + 1;
    } else {
        return 0;
    }
}

- (void)selectAsset:(ALAsset *)asset {
    if ([self isSelectedAsset:asset]) {
        return;
    }
    SYImagePickerViewController *navigationController = (SYImagePickerViewController *)self.navigationController;
    NSUInteger maxSelection = 0;
    if ([navigationController.imagePickerDataSource respondsToSelector:@selector(maxSelectionForImagePickerViewController:)]) {
        maxSelection = [navigationController.imagePickerDataSource maxSelectionForImagePickerViewController:navigationController];
    }
    if (maxSelection > 0 && self.selectedAssetsArray.count >= maxSelection) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:[NSString stringWithFormat:@"最多可以选择%@张图片", @(maxSelection)] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    } else {
        [self.selectedAssetsArray addObject:asset];
        [self reloadData];
    }
}

- (void)deselectAsset:(ALAsset *)asset {
    [self.selectedAssetsArray removeObject:asset];
    [self reloadData];
}

- (void)reloadData {
    BOOL hasSelectedAssets = (self.selectedAssetsArray.count != 0);
    self.previewBarButtonItem.enabled = hasSelectedAssets;
    self.doneBarButtonItem.enabled = hasSelectedAssets;
    [self.collectionView reloadData];
}

#pragma mark - Property method

- (UIBarButtonItem *)previewBarButtonItem {
    if (_previewBarButtonItem == nil) {
        _previewBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"预览" style:UIBarButtonItemStylePlain target:self action:@selector(previewAction)];
        _previewBarButtonItem.enabled = NO;
    }
    return _previewBarButtonItem;
}

- (UIBarButtonItem *)doneBarButtonItem {
    if (_doneBarButtonItem == nil) {
        _doneBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStylePlain target:self action:@selector(doneAction)];
        _doneBarButtonItem.enabled = NO;
    }
    return _doneBarButtonItem;
}

- (ALAssetsLibrary *)assetsLibrary {
    if (nil == _assetsLibrary) {
        _assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
    return _assetsLibrary;
}

- (NSMutableArray *)assetsArray {
    if (_assetsArray == nil) {
        _assetsArray = [NSMutableArray array];
    }
    return _assetsArray;
}

- (NSMutableArray *)selectedAssetsArray {
    if (_selectedAssetsArray == nil) {
        _selectedAssetsArray = [NSMutableArray array];
    }
    return _selectedAssetsArray;
}

@end
