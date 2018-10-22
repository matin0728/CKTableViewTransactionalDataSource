//
//  CKTableViewTransactionalDataSource.mm
//  CKToolbox
//
//  Created by Jonathan Crooke on 17/01/2016.
//  Copyright (c) 2016 Jonathan Crooke. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "CKTableViewTransactionalDataSource.h"
#import "CKTableViewDataSourceCell.h"
#import "CKTableViewSupplementaryDataSource.h"
#import "CKTableViewTransactionalDataSourceCellConfiguration.h"
#import <ComponentKit/CKDataSource.h>
#import <ComponentKit/CKComponentDataSourceAttachController.h>
#import <ComponentKit/CKDataSourceState.h>
#import <ComponentKit/CKDataSourceAppliedChanges.h>
#import <ComponentKit/CKDataSourceItem.h>
#import <ComponentKit/CKDataSourceListener.h>
#import <ComponentKit/CKComponentRootView.h>

static const UITableViewRowAnimation kDefaultAnimation = UITableViewRowAnimationFade;

@interface CKTableViewTransactionalDataSource () <
UITableViewDataSource,
CKDataSourceListener
>
{
  CKDataSource *_componentDataSource;
  CKDataSourceState *_currentState;
  CKComponentDataSourceAttachController *_attachController;
  NSMapTable<UITableViewCell *, CKDataSourceItem *> *_cellToItemMap;
  CKTableViewTransactionalDataSourceCellConfiguration *_defaultCellConfiguration;
  CKTableViewTransactionalDataSourceCellConfiguration *_cellConfiguration;
}
@end


@implementation CKTableViewTransactionalDataSource

- (instancetype)initWithTableView:(UITableView *)tableView
          supplementaryDataSource:(NSObject <CKTableViewSupplementaryDataSource> * _Nullable)supplementaryDataSource
                    configuration:(CKDataSourceConfiguration *)configuration
         defaultCellConfiguration:(CKTableViewTransactionalDataSourceCellConfiguration * _Nullable)cellConfiguration
{
  self = [super init];
  if (self) {
    _componentDataSource = [[CKDataSource alloc] initWithConfiguration:configuration];
    [_componentDataSource addListener:self];

    _tableView = tableView;
    _tableView.dataSource = self;
    [_tableView registerClass:[CKTableViewDataSourceCell class] forCellReuseIdentifier:kReuseIdentifier];

    _attachController = [[CKComponentDataSourceAttachController alloc] init];
    _supplementaryDataSource = supplementaryDataSource;
    _cellConfiguration = cellConfiguration;
    _cellToItemMap = [NSMapTable weakToStrongObjectsMapTable];

    // tableview have one section initially, while ck datasoure have no. This will led to crash
    // at some circumstances.
    [_tableView reloadData];
  }
  return self;
}

#pragma mark - Changeset application

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource applyChangeset:changeset
                                  mode:mode
                              userInfo:userInfo];
}

static void applyChangesToTableView(
                                    UITableView *tableView,
                                    CKComponentDataSourceAttachController *attachController,
                                    NSMapTable<UITableViewCell *, CKDataSourceItem *> *cellToItemMap,
                                    CKDataSourceState *currentState,
                                    CKDataSourceAppliedChanges *changes,
                                    CKTableViewTransactionalDataSourceCellConfiguration *cellConfig
                                    )
{
  [changes.updatedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull indexPath, BOOL * _Nonnull stop) {
    if (CKTableViewDataSourceCell *cell = [tableView cellForRowAtIndexPath:indexPath]) {
      attachToCell(cell, indexPath, [currentState objectAtIndexPath:indexPath], attachController, cellConfig, cellToItemMap);
    }
  }];
  [tableView deleteRowsAtIndexPaths:[changes.removedIndexPaths allObjects] withRowAnimation:cellConfig ? cellConfig.animationRowDelete : kDefaultAnimation];
  [tableView deleteSections:changes.removedSections withRowAnimation:cellConfig ? cellConfig.animationSectionDelete : kDefaultAnimation];
  for (NSIndexPath *from in changes.movedIndexPaths) {
    NSIndexPath *to = changes.movedIndexPaths[from];
    [tableView moveRowAtIndexPath:from toIndexPath:to];
  }
  [tableView insertSections:changes.insertedSections withRowAnimation:cellConfig ? cellConfig.animationSectionInsert : kDefaultAnimation];
  [tableView insertRowsAtIndexPaths:[changes.insertedIndexPaths allObjects] withRowAnimation:cellConfig ? cellConfig.animationRowInsert : kDefaultAnimation];
}

#pragma mark - CKTransactionalComponentDataSourceListener

- (void)componentDataSource:(CKDataSource *)dataSource
     didModifyPreviousState:(CKDataSourceState *)previousState
          byApplyingChanges:(CKDataSourceAppliedChanges *)changes;
{
  CKTableViewTransactionalDataSourceCellConfiguration *cellConfig =
  changes.userInfo[CKTableViewTransactionalDataSourceCellConfigurationKey] ?: _cellConfiguration;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
  dispatch_block_t block = ^{
    [_tableView beginUpdates];
    // Detach all the component layouts for items being deleted
    [self _detachComponentLayoutForRemovedItemsAtIndexPaths:[changes removedIndexPaths]
                                                    inState:previousState];
    CKDataSourceState *state = [_componentDataSource state];
    applyChangesToTableView(_tableView, _attachController, _cellToItemMap, state, changes, cellConfig);
    _currentState = [_componentDataSource state];
    [_tableView endUpdates];
  };
#pragma clang diagnostic pop
  if (cellConfig.animationsDisabled) {
    [UIView performWithoutAnimation:block];
  } else {
    block();
  }
}

- (void)_detachComponentLayoutForRemovedItemsAtIndexPaths:(NSSet *)removedIndexPaths
                                                  inState:(CKDataSourceState *)state
{
  for (NSIndexPath *indexPath in removedIndexPaths) {
    CKComponentScopeRootIdentifier identifier = [[[state objectAtIndexPath:indexPath] scopeRoot] globalIdentifier];
    [_attachController detachComponentLayoutWithScopeIdentifier:identifier];
  }
}


#pragma mark - State

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].model;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].rootLayout.size();
}

#pragma mark - Reload

- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource reloadWithMode:mode userInfo:userInfo];
}

- (void)updateConfiguration:(CKDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource updateConfiguration:configuration mode:mode userInfo:userInfo];
}

#pragma mark - Cell configuration update convenience methods

- (void)applyChangeset:(CKDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
     cellConfiguration:(CKTableViewTransactionalDataSourceCellConfiguration *)cellConfiguration
{
  [self applyChangeset:changeset
                  mode:mode
              userInfo:(cellConfiguration
                        ? @{ CKTableViewTransactionalDataSourceCellConfigurationKey : cellConfiguration }
                        : nil)];
}

- (void)applyChangeset:(CKDataSourceChangeset *)changeset mode:(CKUpdateMode)mode
{
    [self applyChangeset:changeset mode:mode cellConfiguration:nil];
}

- (void)updateConfiguration:(CKDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
          cellConfiguration:(CKTableViewTransactionalDataSourceCellConfiguration *)cellConfiguration
{
  [self updateConfiguration:configuration
                       mode:mode
                   userInfo:(cellConfiguration
                             ? @{ CKTableViewTransactionalDataSourceCellConfigurationKey : cellConfiguration }
                             : nil)];
}

- (CKTableViewTransactionalDataSourceCellConfiguration *)cellConfiguration {
  return _cellConfiguration.copy;
}

#pragma mark - UITableViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.table_view_data_source.cell";

static void attachToCell(CKTableViewDataSourceCell *cell,
                         NSIndexPath *indexPath,
                         CKDataSourceItem *item,
                         CKComponentDataSourceAttachController *attachController,
                         CKTableViewTransactionalDataSourceCellConfiguration *configuration,
                         NSMapTable<UITableViewCell *, CKDataSourceItem *> *cellToItemMap)
{
  CKComponentDataSourceAttachControllerAttachComponentRootLayout(
      attachController,
      {.layoutProvider = item,
       .scopeIdentifier = item.scopeRoot.globalIdentifier,
       .boundsAnimation = item.boundsAnimation,
       .view = cell.rootView,
       .analyticsListener = item.scopeRoot.analyticsListener});

  [cellToItemMap setObject:item forKey:cell];
    
  if (configuration.cellConfigurationFunction) {
    configuration.cellConfigurationFunction(cell, indexPath, item.model);
  }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  CKTableViewDataSourceCell *cell = [_tableView dequeueReusableCellWithIdentifier:kReuseIdentifier forIndexPath:indexPath];
  attachToCell(cell, indexPath, [_currentState objectAtIndexPath:indexPath], _attachController, _cellConfiguration, _cellToItemMap);
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _currentState ? [_currentState numberOfSections] : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _currentState ? [_currentState numberOfObjectsInSection:section] : 0;
}

#pragma mark - CKTableViewSupplementaryDataSource

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView titleForHeaderInSection:section];
  }
  return nil;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView titleForFooterInSection:section];
  }
  return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView canEditRowAtIndexPath:indexPath];
  }
  return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView canMoveRowAtIndexPath:indexPath];
  }
  return NO;
}

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource sectionIndexTitlesForTableView:tableView];
  }
  return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
  }
  return NSNotFound;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
  }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
  }
}


@end
