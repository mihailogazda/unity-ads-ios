#import <XCTest/XCTest.h>
#import "UnityAdsTests-Bridging-Header.h"
#import "UADSInvocation.h"

@interface WebAppTestWebView : UIWebView
@property (nonatomic, assign) BOOL jsInvoked;
@property (nonatomic, strong) NSString *jsCall;
@property (nonatomic, strong) XCTestExpectation *expectation;
@end

@implementation WebAppTestWebView

@synthesize jsInvoked = _jsInvoked;
@synthesize jsCall = _jsCall;
@synthesize expectation = _expectation;

- (id)init {
    self = [super init];
    if (self) {
        [self setJsInvoked:false];
        [self setJsCall:NULL];
        [self setExpectation:NULL];
    }
    
    return self;
}

- (nullable NSString *)stringByEvaluatingJavaScriptFromString:(NSString *)script {
    self.jsInvoked = true;
    self.jsCall = script;
    
    if (self.expectation) {
        [self.expectation fulfill];
        self.expectation = NULL;
    }
    
    return NULL;
}

@end

@interface WebAppTestWebApp : UADSWebViewApp
@end

@implementation WebAppTestWebApp

- (id)init {
    self = [super init];
    if (self) {
    }
    
    return self;
}

- (BOOL)invokeCallback:(UADSInvocation *)invocation {
    return true;
}

@end

@interface WebAppTests : XCTestCase
    @property (nonatomic, strong) NSCondition *blockCondition;
@end

@implementation WebAppTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    nativeCallbackMethodInvoked = false;
    [UADSWebViewApp setCurrentApp:NULL];
    [super tearDown];
}

// TESTS

static BOOL nativeCallbackMethodInvoked = false;

+ (void)nativeCallbackMethod {
    nativeCallbackMethodInvoked = true;
}

- (void)testCreate {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    UADSConfiguration *config = [[UADSConfiguration alloc] initWithConfigUrl:@"http://localhost/"];
    __block BOOL success = true;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [UADSWebViewApp create:config];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        if (error) {
            success = false;
        }
    }];
    
    XCTAssertTrue(success, @"Expectation failed");
    XCTAssertNotNil([UADSWebViewApp getCurrentApp], "Current WebView app should not be NULL after create");
}

- (void)testAddCallback {
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    WebAppTestWebView *webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    UADSNativeCallback *localNativeCallback = [[UADSNativeCallback alloc] initWithCallback:@"nativeCallbackMethod:" receiverClass:@"WebAppTests"];
    
    [[UADSWebViewApp getCurrentApp] addCallback:localNativeCallback];
    UADSNativeCallback *remoteNativeCallback = [[UADSWebViewApp getCurrentApp] getCallbackWithId:[localNativeCallback callbackId]];
    
    XCTAssertNotNil(remoteNativeCallback, @"The WebApp stored callback should not be NULL");
    XCTAssertEqualObjects(localNativeCallback, remoteNativeCallback, @"The local and the WebApp stored callback should be the same object");
    XCTAssertEqual([localNativeCallback callbackId], [remoteNativeCallback callbackId], @"The local and the WebApp stored callback should have the same ID");
}

- (void)testRemoveCallback {
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    WebAppTestWebView *webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    UADSNativeCallback *localNativeCallback = [[UADSNativeCallback alloc] initWithCallback:@"nativeCallbackMethod:" receiverClass:@"WebAppTests"];
    
    [[UADSWebViewApp getCurrentApp] addCallback:localNativeCallback];
    UADSNativeCallback *remoteNativeCallback = [[UADSWebViewApp getCurrentApp] getCallbackWithId:[localNativeCallback callbackId]];
    
    XCTAssertNotNil(remoteNativeCallback, @"The WebApp stored callback should not be NULL");
    
    [[UADSWebViewApp getCurrentApp] removeCallback:localNativeCallback];
    remoteNativeCallback = [[UADSWebViewApp getCurrentApp] getCallbackWithId:[localNativeCallback callbackId]];
    
    XCTAssertNil(remoteNativeCallback, @"The WebApp stored callback should be NULL");

}

- (void)testSetWebView {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];

    XCTAssertNotNil([[UADSWebViewApp getCurrentApp] webView], @"Current WebApps WebView should not be null because it was set");
    XCTAssertEqualObjects(webView, [[UADSWebViewApp getCurrentApp] webView], @"Local and WebApps WebView should be the same object");
}

- (void)testSetConfiguration {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    UADSConfiguration *config = [[UADSConfiguration alloc] initWithConfigUrl:@"http://localhost/"];
    [[UADSWebViewApp getCurrentApp] setConfiguration:config];
    
    XCTAssertNotNil([[UADSWebViewApp getCurrentApp] configuration], @"Current WebApp configuration should not be null");
    XCTAssertEqualObjects(config, [[UADSWebViewApp getCurrentApp] configuration], @"Local configuration and current WebApp configuration should be the same object");
}

- (void)testSetWebAppLoaded {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];

    XCTAssertFalse([[UADSWebViewApp getCurrentApp] webAppLoaded], @"WebApp should not be loaded. It was just created");
    
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];

    XCTAssertTrue([[UADSWebViewApp getCurrentApp] webAppLoaded], @"WebApp should now be \"loaded\". We set the status to true");
}

- (void)testSendEventShouldFail {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    BOOL success = [[UADSWebViewApp getCurrentApp] sendEvent:@"TEST_EVENT_1" category:@"TEST_CATEGORY_1" params:@[]];
    
    XCTAssertFalse(success, @"sendEvent should've failed since webApp is still unloaded");
    XCTAssertFalse([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've not been invoked but was (webviewapp is not loaded so no call should have occured)");
    XCTAssertNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should be null (webviewapp is not loaded so no call should have occured)");
}

- (void)testSendEventShouldSucceed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    __block BOOL success = false;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        success = [[UADSWebViewApp getCurrentApp] sendEvent:@"TEST_EVENT_1" category:@"TEST_CATEGORY_1" params:@[]];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"sendEvent should've succeeded");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
}

- (void)testSendEventWithParamsShouldSucceed_VA_LIST {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        success = [[UADSWebViewApp getCurrentApp] sendEvent:@"TEST_EVENT_1" category:@"TEST_CATEGORY_1"
                                                          param1:@"Test", [NSNumber numberWithInt:1], [NSNumber numberWithBool:true], nil];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"sendEvent should've succeeded");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
}

- (void)testSendEventWithParamsShouldSucceed_ARRAY {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        NSArray *params = [[NSArray alloc] initWithObjects:@"Test", [NSNumber numberWithInt:1], [NSNumber numberWithBool:true], nil];
        success = [[UADSWebViewApp getCurrentApp] sendEvent:@"TEST_EVENT_1" category:@"TEST_CATEGORY_1" params:params];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });

    XCTAssertTrue(success, @"sendEvent should've succeeded");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
}

- (void)testInvokeMethodShouldFailWebAppNotLoaded {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    BOOL success = false;
    success = [[UADSWebViewApp getCurrentApp] invokeMethod:@"testMethod" className:@"TestClass" receiverClass:@"WebAppTests" callback:@"nativeCallbackMethod:" params:@[]];
    //[(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
    
    XCTAssertFalse(success, @"invokeMethod -method should've returned false because webApp is not loaded");
    XCTAssertFalse([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've not been invoked but was (webviewapp is not loaded so no call should have occured)");
    XCTAssertNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should be null (webviewapp is not loaded so no call should have occured)");
}

- (void)testInvokeMethodShouldSucceedMethodAndClassNull {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        success = [[UADSWebViewApp getCurrentApp] invokeMethod:@"testMethod" className:@"TestClass" receiverClass:NULL callback:NULL params:@[]];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"invokeMethod -method should've returned true");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
}

- (void)testInvokeMethodShouldSucceed {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        success = [[UADSWebViewApp getCurrentApp] invokeMethod:@"testMethod" className:@"TestClass" receiverClass:@"WebAppTests" callback:@"nativeCallbackMethod:" params:@[]];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"invokeMethod -method should've returned true");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
    //XCTAssertTrue(nativeCallbackMethodInvoked, @"Native callback method should've been invoked but was not");
}

- (void)testInvokeMethodWithParamsShouldSucceed {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        NSArray *params = [[NSArray alloc] initWithObjects:@"Test", [NSNumber numberWithInt:1], [NSNumber numberWithBool:true], nil];
        success = [[UADSWebViewApp getCurrentApp] invokeMethod:@"testMethod" className:@"TestClass" receiverClass:@"WebAppTests" callback:@"nativeCallbackMethod:" params:params];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"invokeMethod -method should've returned true");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
    //XCTAssertTrue(nativeCallbackMethodInvoked, @"Native callback method should've been invoked but was not");
}

- (void)testInvokeCallbackShouldFailWebAppNotLoaded {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    UADSInvocation *invocation = [[UADSInvocation alloc] init];
    //NSArray *params = @[[NSString stringWithFormat:@"Test"], [NSNumber numberWithInt:1], [NSNumber numberWithBool:true], nil];
    NSMutableArray *params = [[NSMutableArray alloc] init];
    [params addObject:[NSString stringWithFormat:@"Test"]];
    [params addObject:[NSNumber numberWithInt:1]];
    [params addObject:[NSNumber numberWithBool:true]];
    [invocation setInvocationResponseWithStatus:@"OK" error:NULL params:[NSArray arrayWithArray:params]];
    
    __block BOOL success = false;
    success = [[UADSWebViewApp getCurrentApp] invokeCallback:invocation];
    
    XCTAssertFalse(success, @"invokeCallback -method should've returned false because webApp is not loaded");
    XCTAssertFalse([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've not been invoked but was (webviewapp is not loaded so no call should have occured)");
    XCTAssertNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should be null (webviewapp is not loaded so no call should have occured)");
}

- (void)testInvokeCallbackShouldSucceed {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    UADSInvocation *invocation = [[UADSInvocation alloc] init];
    [invocation setInvocationResponseWithStatus:@"OK" error:NULL params:@[@"Test", @12345, @true]];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        success = [[UADSWebViewApp getCurrentApp] invokeCallback:invocation];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"invokeCallback -method should've succeeded");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
}

- (void)testInvokeCallbackWithErrorShouldSucceed {
    WebAppTestWebView *webView;
    UADSWebViewApp *webViewApp = [[UADSWebViewApp alloc] init];
    [UADSWebViewApp setCurrentApp:webViewApp];
    webView = [[WebAppTestWebView alloc] init];
    [[UADSWebViewApp getCurrentApp] setWebView:webView];
    [[UADSWebViewApp getCurrentApp] setWebAppLoaded:true];
    [[UADSWebViewApp getCurrentApp] setWebAppInitialized:true];
    
    UADSInvocation *invocation = [[UADSInvocation alloc] init];
    [invocation setInvocationResponseWithStatus:@"ERROR" error:@"TEST_ERROR_1" params:@[@"Test", @12345, @true]];
    
    __block BOOL success = false;
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        success = [[UADSWebViewApp getCurrentApp] invokeCallback:invocation];
        [(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] setExpectation:expectation];
        [self waitForExpectationsWithTimeout:60 handler:^(NSError * _Nullable error) {
        }];
    });
    
    XCTAssertTrue(success, @"invokeCallback -method should've succeeded");
    XCTAssertTrue([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsInvoked], @"WebView invokeJavascript should've been invoked but was not");
    XCTAssertNotNil([(WebAppTestWebView *)[[UADSWebViewApp getCurrentApp] webView] jsCall], @"The invoked JavaScript string should not be null");
}

@end