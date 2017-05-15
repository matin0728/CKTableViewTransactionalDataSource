//
//  CKTableViewTransactionalDataSource.h
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

#import <UIKit/UIKit.h>
#import <ComponentKit/ComponentKit.h>
#import "CKTableViewTransactionalDataSourceCellConfiguration.h"
#import "CKTableViewSupplementaryDataSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Largely clones the interface of CKCollectionViewTransactionalDataSource (via
 CKTransactionalDataSourceInterface), with some additional features, related to
 utilising UITableViewCell's native features.
 */
@interface CKTableViewTransactionalDataSource : NSObject

/**
 *	Designated initializer.
 *
 *	@param tableView The tableView is held strongly and its datasource property will be set to the receiver.
 *	@param supplementaryDataSource	UITableViewDataSource subset methods from CKTableViewSupplementaryDataSource will be forwarded to this object. Weak reference.
 *	@param configuration see CKTransactionalComponentDataSourceConfiguration.
 *	@param cellConfiguration Initial cell configuration instance, or nil.
 */
- (instancetype)initWithTableView:(UITableView *)tableView
          supplementaryDataSource:(nullable NSObject <CKTableViewSupplementaryDataSource> *)supplementaryDataSource
                    configuration:(CKTransactionalComponentDataSourceConfiguration *)configuration
         defaultCellConfiguration:(nullable CKTableViewCellConfiguration *)cellConfiguration NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 Convenience method for passing a CKTableViewTransactionalDataSourceCellConfiguration
 object via CKTransactionalDataSourceInterface's userInfo method (and dictionary) when
 applying a changeset. @see CKTransactionalComponentDataSource.

 @param cellConfiguration	A cell configuration object to use during this update.
 */
- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
     cellConfiguration:(nullable CKTableViewCellConfiguration *)cellConfiguration;

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode;

/**
 @return The model associated with a certain index path in the view.

 As stated above components are generated asynchronously and on a background thread. This means that a changeset is enqueued
 and applied asynchronously when the corresponding component tree is generated. For this reason always use this method when you
 want to retrieve the model associated to a certain index path in the view (e.g in didSelectRowAtIndexPath: )
 */
- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 @return The layout size of the component tree at a certain indexPath.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

/** @see `CKTransactionalComponentDataSource` */
- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/**
 Convenience method for passing a CKTableViewTransactionalDataSourceCellConfiguration
 object via CKTransactionalDataSourceInterface's userInfo method (and dictionary) when
 updating the data source's configuration. @see CKTransactionalComponentDataSource.

 @param cellConfiguration	A cell configuration object to use during this update.
 */
- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
          cellConfiguration:(nullable CKTableViewCellConfiguration *)cellConfiguration;

/**
 UITableView instance passed to the initializer.
 */
@property (readonly, nonatomic, strong) UITableView *tableView;

/**
 *	The default cell configuration specified in the initializer.
 *	@note Copy is always returned. Use accessor to mutate the copies and pass in updates.
 */
@property (readonly, nonatomic, copy) CKTableViewCellConfiguration *cellConfiguration;

/**
 Supplementary views are not handled with components; the datasource will forward any call to
 `collectionView:viewForSupplementaryElementOfKind:atIndexPath` to this object.
 */
@property (readonly, nonatomic, weak) id<CKTableViewSupplementaryDataSource> supplementaryDataSource;

@end

NS_ASSUME_NONNULL_END
