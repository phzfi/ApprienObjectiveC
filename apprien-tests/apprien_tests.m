//
//  apprien_tests.m
//  apprien-tests
//
//  Created by phz on 22.2.2021.
//

#import <XCTest/XCTest.h>
#import "ApprienSdk.h"
#import "IapProduct.h"

@interface apprien_tests : XCTestCase

@end

@implementation apprien_tests

ApprienSdk *apprienSdk;
//NSDictionary *productsAndKeys;
NSString *testPackageName = @"fi.phz.appriensdkdemo";
NSString *token = @"";
NSMutableArray *products;
NSString *defaultIAPid = @"test-default-id";
NSArray <NSString *> *testIAPids;

- (void)setUp {
    @autoreleasepool {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    // Setup products for testing
    testIAPids = @[@"test_product_1_sku", @"test_product_2_sku", @"test_product_3_sku", @"test_subscription_03", @"test_subscription_01"];
        NSString *path = [NSHomeDirectory() stringByAppendingString:@"/workspace/github/ApprienObjectiveC/token.txt"];
        token =[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (token == nil) {
            token = @"";
        }
    IapProduct *apprienProduct = [[IapProduct alloc] initWithBaseIapId:defaultIAPid];

    products = [apprienProduct FromIAPCatalog:testIAPids];
    ApprienIntegrationType integrationType = GooglePlayStore;
    apprienSdk = [[ApprienSdk alloc] initWithGamePackage:testPackageName integrationType:integrationType token:[token stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""]];
        
    }
    apprienSdk.DEBUGGING_ENABLED = TRUE;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    @autoreleasepool {
        apprienSdk = nil;
        products = nil;
        testIAPids = nil;
    }
}

- (void)testGamePackageNameReturnsSomething {
    NSString *packageName = [apprienSdk gamePackageName];
    //the variable testPackageName is given in setup
    XCTAssertTrue([packageName isEqual:testPackageName] == TRUE);
}

- (void)testSettingAndGettingToken {
    NSString *tokenName = apprienSdk.token;
    XCTAssertTrue([token isEqual:tokenName] == TRUE);
    apprienSdk.token = @"testToken";
    tokenName = [apprienSdk token];
    XCTAssertTrue([@"testToken" isEqual:tokenName] == TRUE);
}

- (void)testSettingStoreIdentifier {
    NSString *tokenName = [apprienSdk StoreIdentifier];
    XCTAssertTrue([@"google" isEqual:tokenName] == TRUE);
}


- (void)testSettingIntegrationType {
    @autoreleasepool {
        //Default is google set in the setup function
        XCTAssertTrue([apprienSdk getIntegrationType] == GooglePlayStore);
        apprienSdk = nil;
        const ApprienIntegrationType appleIntegration = AppleAppStore;
        apprienSdk = [[ApprienSdk alloc] initWithGamePackage:testPackageName integrationType:appleIntegration token:token];
       
        const ApprienIntegrationType resultIntegrationType = apprienSdk.IntegrationType;
        XCTAssertTrue(resultIntegrationType == appleIntegration);
    }
}

//Quick test to check that the api returns nstrings and they have base url in it.
- (void)testApprienReturnUrls {
    @autoreleasepool {
        NSString *baseUrl = @"http://";
        //IOS7 compatible way of checking if string contains some other string
        XCTAssertTrue([[apprienSdk REST_GET_ALL_PRICES_URL] rangeOfString:baseUrl].location != NSNotFound);
        XCTAssertTrue([[apprienSdk REST_GET_PRICE_URL] rangeOfString:baseUrl].location != NSNotFound);
        XCTAssertTrue([[apprienSdk REST_GET_VALIDATE_TOKEN_URL] rangeOfString:baseUrl].location != NSNotFound);
        XCTAssertTrue([[apprienSdk REST_POST_ERROR_URL] rangeOfString:baseUrl].location != NSNotFound);
        XCTAssertTrue([[apprienSdk REST_POST_PRODUCTS_SHOWN_URL] rangeOfString:baseUrl].location != NSNotFound);
        XCTAssertTrue([[apprienSdk REST_POST_RECEIPT_URL] rangeOfString:baseUrl].location != NSNotFound);
        XCTAssertTrue([[apprienSdk REST_GET_APPRIEN_STATUS] rangeOfString:baseUrl].location != NSNotFound);
    }
}

//Test that price Url gets changed
- (void)testPriceUrlGetsChanged {
    @autoreleasepool {
        NSString *baseUrl = @"http://";
        [apprienSdk setREST_GET_PRICE_URL:baseUrl];
        //IOS7 compatible way of checking if string contains some other string
        XCTAssertTrue([[apprienSdk REST_GET_PRICE_URL] rangeOfString:baseUrl].location != NSNotFound);
  
        [apprienSdk setREST_GET_PRICE_URL:@""];
        XCTAssertTrue([[apprienSdk REST_GET_PRICE_URL] rangeOfString:baseUrl].location == NSNotFound);
    }
}
 
//Test that all price Url gets changed
- (void)testAllPriceUrlGetsChanged {
    @autoreleasepool {
        NSString *baseUrl = @"http://";
        [apprienSdk setREST_GET_ALL_PRICES_URL:baseUrl];
        //IOS7 compatible way of checking if string contains some other string
        XCTAssertTrue([[apprienSdk REST_GET_ALL_PRICES_URL] rangeOfString:baseUrl].location != NSNotFound);
  
        [apprienSdk setREST_GET_ALL_PRICES_URL:@""];
        XCTAssertTrue([[apprienSdk REST_GET_ALL_PRICES_URL] rangeOfString:baseUrl].location == NSNotFound);
    }
}

- (void)testApprienIdentifier {
    NSString *result = [apprienSdk ApprienIdentifier];
    XCTAssertTrue([result isEqualTo:@""] == FALSE && result.length == 1 );
}

- (void)testDeviceUniqueIdentifier {
    NSString *result = [apprienSdk DeviceUniqueIdentifier];
    XCTAssertTrue([result isEqualTo:@""]);
}


- (void)testRequestTimeoutIsNotZeroByDefault {
    int result = [apprienSdk REQUEST_TIMEOUT];
    XCTAssertTrue(result != 0);
}

- (void)testFetchingManyProductsShouldSucceed {

    NSArray *expectedVariantIdPart = @[@"apprien", @"apprien", @"test_product_3_sku", @"test_subscription_03", @"apprien"];
    __block BOOL fetchPricesFinished;
    __block NSArray * productsOut = [[NSArray alloc] init];
    
    [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        productsOut = productsWithPrices;
        fetchPricesFinished = TRUE;
    }];

    //wait for async to complete
    while (!fetchPricesFinished) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [productsOut count]; i++) {
        IapProduct *product = productsOut[i];
        NSString *expectedStringToBeFound = expectedVariantIdPart[i];
        //IOS7 compatible way of checking if string contains some other string
        XCTAssertTrue([product.apprienVariantIAPId rangeOfString:expectedStringToBeFound].location != NSNotFound);
    }
}



- (void)testJSONParserCanParseProducts {
    #define MAKE_STRING(x) @#x
    NSString *productsString = MAKE_STRING("products:
    [
        { "id": "1001", "type": "Regular" },
        { "id": "1002", "type": "Chocolate" },
        { "id": "1003", "type": "Blueberry" },
        { "id": "1004", "type": "Devil's Food" }
    ]");
    NSArray *expectedVariantIdPart = @[@"apprien", @"apprien", @"test_product_3_sku", @"test_subscription_03", @"apprien"];
}

- (void)testFetchingProductsWithBadURLShouldFail {

    apprienSdk.REST_GET_ALL_PRICES_URL = [[@"http://localhost:" stringByAppendingString:@"123123"] stringByAppendingString:@"/api/v0/stores/google/games/{0}/products/{1}/prices"];

    NSArray *expectedVariantIdPart = [[NSArray alloc] initWithArray:products];
    __block BOOL fetchPricesFinished;
    [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
        fetchPricesFinished = TRUE;
    }];

    //wait for async to complete
    while (!fetchPricesFinished) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [products count]; i++) {
        IapProduct *product = products[i];
        IapProduct *expectedStringToBeFound = expectedVariantIdPart[i];
        XCTAssertEqual(product.apprienVariantIAPId, expectedStringToBeFound.apprienVariantIAPId);
    }
}

- (void)testFetchingProductsWithBadTokenShouldNotFetchVariants {

    [apprienSdk setToken:@"badToken"];
    NSArray *expectedVariantIdPart = [[NSArray alloc] initWithArray:products];
    __block BOOL fetchPricesFinished;
    [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
        fetchPricesFinished = TRUE;
    }];
    //wait for async to complete
    while (!fetchPricesFinished) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [products count]; i++) {
        IapProduct *product = products[i];
        IapProduct *expectedStringToBeFound = expectedVariantIdPart[i];
        XCTAssertEqual(product.apprienVariantIAPId, expectedStringToBeFound.apprienVariantIAPId);
    }
}

- (void)testFetchingNonVariantProductsShouldReturnBaseIAPId {

//TODO: implement this after get price for single product is made
}


- (void)testFetchingProductsWithTimeOutShouldGiveNonVariants {
    // Configure the SDK timeout to 0.1 second, but make the request take 0.5 seconds
    // Non-variant products should be fetched
    apprienSdk.REQUEST_TIMEOUT = 0.0000000001f;

    NSArray *expectedVariantIdPart = [[NSArray alloc] initWithArray:products];
    __block BOOL fetchPricesFinished;
    [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
        fetchPricesFinished=TRUE;
    }];

    //wait for async to complete
    while (!fetchPricesFinished) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [products count]; i++) {
        IapProduct *product = products[i];
        IapProduct *expectedStringToBeFound = expectedVariantIdPart[i];
        XCTAssertEqual(product.apprienVariantIAPId, expectedStringToBeFound.apprienVariantIAPId);
    }
}

//TODO: test apprien cpp sdk performance with high product count
//TODO: test apprien sdk for memory leaks
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.

    }];
}


size_t writeFunction(void *ptr, size_t size, size_t nmemb, char *data) {
    return size * nmemb;
}

- (void)testProductsShown {
    __block BOOL postReceiptFinished;
    [apprienSdk ProductsShown:products completionHandler:^(){
        postReceiptFinished = TRUE;
    }];
    while (postReceiptFinished == FALSE) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
    }


    XCTAssertEqual(postReceiptFinished, TRUE);
    
}

- (void)testPostReceipt {
    __block BOOL postReceiptFinished;
    NSString *receipt = @"test receipt,  price: 402";
    [apprienSdk PostReceipt:receipt completionHandler:^(){

        postReceiptFinished = TRUE;
    }];
    while(postReceiptFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }
    for (int i = 0; i < [products count]; i++) {
        IapProduct *product = products[i];
        NSString *expectedIapId = [testIAPids[i] stringByAppendingString:@"-variant"];
        NSString *resultId = product.apprienVariantIAPId;
        XCTAssertEqual(expectedIapId, resultId);
    }
}

- (void)testGetBaseIAPId {
    NSString *baseIapId = [apprienSdk GetBaseIAPId:defaultIAPid];
    XCTAssertTrue([baseIapId rangeOfString:@"test"].location != NSNotFound);

    baseIapId = [apprienSdk GetBaseIAPId:@"z_test.apprien_sku"];
    NSString *expectedRsult = @"test";
    XCTAssertTrue([baseIapId rangeOfString:@"test"].location != NSNotFound);
}

//Test against the real Apprien service. If these fail the server is most likely down.
- (void)testConnection {
    __block BOOL testConnectionOk;
    __block BOOL testConnectionFinished;
    
    [apprienSdk TestConnection:^(BOOL statusCheck, BOOL tokenCheck) {
        if(statusCheck && tokenCheck){
            testConnectionOk = TRUE;
        }
        testConnectionFinished = TRUE;
    }];

    while(testConnectionFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(testConnectionOk);
}

- (void)testTokenValidity {
    __block BOOL tokenOk;
    __block BOOL checkTokenFinished;
    [apprienSdk CheckTokenValidity: ^(BOOL tokenIsValid) {
            tokenOk = tokenIsValid;
            checkTokenFinished = TRUE;
    }];
    while(checkTokenFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(tokenOk);
}

//Test Apprien service
- (void)testApprienServiceStatus {
    __block BOOL serviceOk;
    __block BOOL serviceCheckFinished;
    [apprienSdk CheckServiceStatus:^(BOOL serviceIsOk) {
        serviceOk = serviceIsOk;
        serviceCheckFinished = TRUE;
    }];
    while(serviceCheckFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(serviceOk);
}

//Test Apprien service
- (void)testPlainRequest {
    __block BOOL serviceCheckFinished;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
       [request setURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/s/2iodh4vg0eortkl/facts.json"]];
       [request setHTTPMethod:@"GET"];
       [request addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
       [request addValue:@"text/plain" forHTTPHeaderField:@"Accept"];

       NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
       [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
       NSString *requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
       NSData * responseData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
       NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
       NSLog(@"requestReply: %@", jsonDict);
       serviceCheckFinished = TRUE;
       }] resume];
    
    while(serviceCheckFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(serviceCheckFinished);
}

//Test Apprien service
- (void)testApprienServiceStatusPlainRequest2 {
    __block BOOL serviceCheckFinished;

    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];

    NSURLSession *sessionWithoutADelegate = [NSURLSession sessionWithConfiguration:defaultConfiguration];
    NSURL *url = [NSURL URLWithString:@"http://game.apprien.com/status"];
     
    [[sessionWithoutADelegate dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Got response %@ with error %@.\n", response, error);
        NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        serviceCheckFinished = TRUE;
    }] resume];
    while(serviceCheckFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(serviceCheckFinished);
}

- (void)testApprienServiceStatusPlainRequest3 {
    __block BOOL serviceCheckFinished;

    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
  
    NSURLSession *sessionWithoutADelegate = [NSURLSession sessionWithConfiguration:defaultConfiguration];
    NSURL *url = [NSURL URLWithString:@"http://game.apprien.com/status"];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
       [request setURL:[NSURL URLWithString:@"http://game.apprien.com/status"]];
       [request setHTTPMethod:@"GET"];

    [request addValue:@"Bearer: $2y$10$snfk2X/5.XV4Jjnmx4C1Qeo9DNAa6tIi3VJA6EEpqzacJqY6XWGVm" forHTTPHeaderField:@"Authorization "];
    [[sessionWithoutADelegate dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Got response %@ with error %@.\n", response, error);
        NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        serviceCheckFinished = TRUE;
    }] resume];
    while(serviceCheckFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(serviceCheckFinished);
}

- (void)testApprienServiceStatusPlainRequest4 {
    __block BOOL serviceOk;
    __block BOOL serviceCheckFinished;

    NSURLSessionConfiguration *defaultConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *sessionWithoutADelegate = [NSURLSession sessionWithConfiguration:defaultConfiguration];
    NSURL *url = [NSURL URLWithString:@"http://game.apprien.com/api/v1/stores/google/games/fi.phz.appriensdkdemo/prices"];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
       [request setURL:[NSURL URLWithString:@"http://game.apprien.com/status"]];
       [request setHTTPMethod:@"GET"];

    [request addValue:@"Bearer:$2y$10$snfk2X/5.XV4Jjnmx4C1Qeo9DNAa6tIi3VJA6EEpqzacJqY6XWGVm" forHTTPHeaderField:@"Authorization "];
    [[sessionWithoutADelegate dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"Got response %@ with error %@.\n", response, error);
        NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        serviceCheckFinished = TRUE;
    }] resume];
    while(serviceCheckFinished == FALSE){
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 2.25, false);
    }

    XCTAssertTrue(serviceCheckFinished);
}
@end
