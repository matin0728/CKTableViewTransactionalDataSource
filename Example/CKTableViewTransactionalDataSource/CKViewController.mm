//
//  CKViewController.m
//  CKTableViewTransactionalDataSource
//
//  Created by gaojiji@gmail.com on 05/15/2017.
//  Copyright (c) 2017 gaojiji@gmail.com. All rights reserved.
//

#import "CKViewController.h"
#import <CKTableViewTransactionalDataSource/CKTableViewTransactionalDataSource.h>

@interface CKViewController () <CKComponentProvider, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) CKTableViewTransactionalDataSource *datasource;
@end

@implementation CKViewController

- (void)viewDidLoad {

    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    self.tableView.frame = self.view.bounds;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;

    CKDataSourceConfiguration *config =
    [[CKDataSourceConfiguration alloc]
     initWithComponentProvider:self.class context:nil sizeRange:CKSizeRange(CGSizeMake(self.view.bounds.size.width, 0), CGSizeMake(self.view.bounds.size.width, INFINITY))];
    self.tableView.delegate = self;

    // datasource
    self.datasource =
    [[CKTableViewTransactionalDataSource alloc]
     initWithTableView:self.tableView
     supplementaryDataSource:nil
     configuration:config
     defaultCellConfiguration:[CKTableViewCellConfiguration noAnimationConfig]];


    // add data
    CKDataSourceChangesetBuilder *changeset = [CKDataSourceChangesetBuilder new];
    [changeset withInsertedSections:[NSIndexSet indexSetWithIndex:0]];
    NSMutableDictionary *inserts = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < 100; i++) {
        inserts[[NSIndexPath indexPathForRow:i inSection:0]] = @0;
    }
    [changeset withInsertedItems:inserts];
    [self.datasource applyChangeset:changeset.build mode:CKUpdateModeSynchronous];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.datasource sizeForItemAtIndexPath:indexPath].height;
}


+ (CKComponent *)componentForModel:(id<NSObject>)model context:(id<NSObject>)context {
    return [CKComponent newWithView:{
        UIView.class, {
            {@selector(setBackgroundColor:), UIColor.brownColor},
            {CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @30}
        }
    } size:{.height = 60}];
}


@end
