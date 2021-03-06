// Copyright © 2017 DWANGO Co., Ltd.

#import "CBBWKWebViewDataBus.h"
#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController () <WKNavigationDelegate, WKUIDelegate>
@property (nonatomic) WKWebView* webView;
@property (nonatomic) CBBDataBus* dataBus;
@property (atomic) NSInteger counter;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;

    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(4, 30, width - 8, 30)];
    label.text = @"Native";
    [self.view addSubview:label];

    // ボタンを準備
    [self addButton:CGRectMake(4, 70, width - 8, 30) title:@"Start sending 10000 request from Native" action:@selector(onStart:)];

    // WKWebViewを準備（※この時点ではまだコンテンツを読み込まない）
    _webView = [[WKWebView alloc]
        initWithFrame:CGRectMake(4, height / 2 + 4, width - 8, height / 2 - 8)];
    _webView.layer.borderWidth = 2.0f;
    _webView.layer.borderColor = [[UIColor blueColor] CGColor];
    _webView.layer.cornerRadius = 10.0f;
    _webView.navigationDelegate = self;
    _webView.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.UIDelegate = self;
    // WKWebView　は App bundle のファイルを読めない為, bundleの内容を tmp
    // へコピーしてそこから読み込む
    [self copyWithTarget:@"index.html"];
    [self copyWithTarget:@"script.js"];
    [self.view addSubview:_webView];

    // CBBDataBusを準備
    _dataBus = [[CBBWKWebViewDataBus alloc] initWithWKWebView:_webView];
    _counter = 0;
    __weak typeof(self) weakSelf = self;
    [_dataBus addHandler:^(NSArray* _Nonnull data) {
        if ([@"Request" isEqualToString:data[0]]) {
            [weakSelf.dataBus sendData:@[ @"Response" ]];
        } else {
            weakSelf.counter++;
            if (0 == weakSelf.counter % 10000) {
                NSLog(@"Received 10000 response");
                UIAlertController* alert = [UIAlertController
                    alertControllerWithTitle:@"Alert from Native"
                                     message:@"Received 10000 response"
                              preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction* ok = [UIAlertAction
                    actionWithTitle:@"OK"
                              style:UIAlertActionStyleDefault
                            handler:^(UIAlertAction* action) {
                                [alert dismissViewControllerAnimated:YES completion:nil];
                            }];
                [alert addAction:ok];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
        }
    }];

    // WKWebView にコンテンツを読み込む（CBBDataBusがインジェクトされる）
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@/index.html", [self getTmpDirectory]]];
    [_webView loadFileURL:url allowingReadAccessToURL:url];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)addButton:(CGRect)frame title:(NSString*)title action:(SEL)sel
{
    UIButton* b = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    b.frame = frame;
    b.layer.cornerRadius = 2.0;
    b.layer.borderColor = [[UIColor blueColor] CGColor];
    b.layer.borderWidth = 1.0;
    [b setTitle:title forState:UIControlStateNormal];
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:b];
}

- (void)onStart:(id)inSender
{
    NSLog(@"sending 10000 request");
    const int threadNumber = 100;
    NSOperationQueue* threads[threadNumber];

    for (int i = 0; i < threadNumber; i++) {
        threads[i] = [[NSOperationQueue alloc] init];
        __weak typeof(self) weakSelf = self;
        [threads[i] addOperationWithBlock:^{
            for (int i = 0; i < 100; i++) {
                [weakSelf.dataBus sendData:@[ @"Request" ]];
            }
        }];
    }
}

- (NSString*)getTmpDirectory
{
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"www"];
}

// AppBundleの内容はWKWebViewから参照できないのでテンポラリディレクトリにコピーして用いる
- (BOOL)copyWithTarget:(NSString*)target
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* sourceFile = [mainBundle pathForResource:target
                                                ofType:@""
                                           inDirectory:@""];
    NSString* tmpFolder = [self getTmpDirectory];
    [[NSFileManager defaultManager] createDirectoryAtPath:tmpFolder
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    NSString* destFile = [tmpFolder stringByAppendingPathComponent:target];
    NSError* err;
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:sourceFile]) {
        return NO;
    }
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    CFRelease(uuidString);
    CFRelease(uuidRef);
    BOOL destExists = [fileManager fileExistsAtPath:destFile];
    if (destExists && ![fileManager removeItemAtPath:destFile error:nil])
        return NO;
    if (!destExists && ![fileManager createDirectoryAtPath:[destFile stringByDeletingLastPathComponent]
                               withIntermediateDirectories:YES
                                                attributes:nil
                                                     error:nil]) {
        return NO;
    }
    BOOL result = [fileManager copyItemAtPath:sourceFile toPath:destFile error:nil];
    if (err) {
        NSLog(@"error: %@", err);
    }
    NSLog(@"copy \"%@\" to \"%@\" <%s>", sourceFile, destFile, result ? "succeed" : "failed");
    return result;
}

// JavaScript側でalertを発行した時の処理
- (void)webView:(WKWebView*)webView runJavaScriptAlertPanelWithMessage:(NSString*)message initiatedByFrame:(WKFrameInfo*)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController* alert =
        [UIAlertController alertControllerWithTitle:@"Alert from JS"
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK"
                                                 style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction* action) {
                                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                                   completionHandler();
                                               }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
