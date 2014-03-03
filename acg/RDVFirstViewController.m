// RDVFirstViewController.m
// RDVTabBarController
//
// Copyright (c) 2013 Robert Dimitrov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "RDVFirstViewController.h"
@interface RDVFirstViewController ()<MJRefreshBaseViewDelegate>
{
    NSMutableArray *current_playList;
    NSMutableArray *requestData_playList;
    NSInteger index;
    MJRefreshHeaderView *_header;
    MJRefreshFooterView *_footer;
}
@end
@implementation RDVFirstViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
            //当前播放列表数据
        current_playList=[NSMutableArray arrayWithObjects: nil];
            //网络请求返回的数据
        requestData_playList=[NSMutableArray arrayWithObjects: nil];
            //初始化index=1为第一页
        index=1;

    }
    return self;
}
-(void) initTableView{
    if( ([[[UIDevice currentDevice] systemVersion] doubleValue]>=7.0))
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        
    }
    
    /**
     *  列表初始化
     */
    self.tableView=[[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.tableView setDataSource:(id<UITableViewDataSource>)self];
    [self.tableView setDelegate:(id<UITableViewDelegate>)self];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleBottomMargin];
    [self.view addSubview:self.tableView];
    
    
    
}
#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initTableView];
    
    /**
     *  请求结束的回调
     */
    __block RDVFirstViewController *_self=self;
    self.requestFinishBlock=^(BOOL flag) {
        if (flag) {
            
                // 主线程执行：
            dispatch_async(dispatch_get_main_queue(), ^{
                    // something
                [_self.tableView reloadData];
                    // 2秒后刷新表格
                [_footer performSelector:@selector(endRefreshing) withObject:nil afterDelay:1.0];
                [_header performSelector:@selector(endRefreshing) withObject:nil afterDelay:1.0];
                [_self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
            });
            
            
        }
        else
        {
                // 主线程执行：
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"加载失败" message:@"网络不给力啊" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                [alert show];
                    // 延迟2秒执行：
                double delayInSeconds = 2.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                        // code to be executed on the main queue after delay
                    [alert dismissWithClickedButtonIndex:0 animated:YES];
                });
                
            });
            
        }
    };
    
        //添加下拉刷新
    _header = [[MJRefreshHeaderView alloc] initWithScrollView:self.tableView];
    _header.delegate = self;
    _header.scrollView = self.tableView;
    _header.beginRefreshingBlock=^(MJRefreshBaseView *refreshView) {
        index=1;
        
            //  后台执行：
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self requestData:self.requestFinishBlock];
            
        });
        
        
        
        
        
        
    };
    
    
    
        //添加上拉加载更多
    _footer = [[MJRefreshFooterView alloc] init];
    _footer.delegate = self;
    _footer.scrollView = self.tableView;
    _footer.beginRefreshingBlock=^(MJRefreshBaseView *refreshView) {
        index++;
        /**
         *  进入上拉加载更多
         */
            //  后台执行：
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
                // something
            [self requestData:self.requestFinishBlock];
            
            
        });
        
        
        
    };
    
        // 0.5秒后自动下拉刷新
    [_header performSelector:@selector(beginRefreshing) withObject:nil afterDelay:1.0];
    

    
    
}
-(void)requestData:(RequestFinished)finishedBlock
{
    
    
    
        //创建NSURLRequest
    NSString *str=[NSString stringWithFormat:@"http://moe.fm/listen/playlist?api=json&perpage=10&page=%ld&api_key=%@",(long)index,APPKEY];
    NSMutableURLRequest* urlrequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:str] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:6.0];
    [urlrequest setHTTPMethod:@"GET"];
    NSError* error = nil;
    /**
     *  同步请求
     */
    NSData* data = [NSURLConnection sendSynchronousRequest:urlrequest returningResponse:NULL error:&error];
    if(!error){
            //清空旧的请求数据
        if (requestData_playList.count>0) {
            [requestData_playList removeAllObjects];
        }
            //获得数据
        id result=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        id playInfo = [[result objectForKey:@"response"]objectForKey:@"playlist"];
            //获得网络播放数据并填充到列表数组
        [requestData_playList setArray:playInfo];
        
            //判断页数
        if (index==1) {
            
            [current_playList setArray:requestData_playList];
            
        }
        else
        {
            
            [current_playList addObjectsFromArray:requestData_playList];
        }
        if(finishedBlock) {
            finishedBlock(YES);
        }
        
        
        
        
        
    }
    NSString* errorString = [error localizedDescription];
    if (errorString != nil) {
        if(finishedBlock) {
            finishedBlock(NO);
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
}

@end
