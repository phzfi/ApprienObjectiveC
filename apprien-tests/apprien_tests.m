//
//  apprien_tests.m
//  apprien-tests
//
//  Created by phz on 22.2.2021.
//

#import <XCTest/XCTest.h>
#import "ApprienSdk.h"
#import "ApprienProduct.h"

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
    ApprienProduct *apprienProduct = [[ApprienProduct alloc] initWithBaseIapId:defaultIAPid];

    products = [apprienProduct FromIAPCatalog:testIAPids];

    apprienSdk = [[ApprienSdk alloc] init];
    [apprienSdk ApprienManager:testPackageName integrationType:GooglePlayStore token:[token stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""]];
    }
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
    NSString *tokenName = [apprienSdk token];
    XCTAssertTrue([token isEqual:tokenName] == TRUE);
    [apprienSdk setToken:@"testToken"];
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
        XCTAssertTrue(apprienSdk.integrationType == GooglePlayStore);
        apprienSdk = nil;
        const ApprienIntegrationType appleIntegration = AppleAppStore;
        apprienSdk = [[ApprienSdk alloc] init];
        [apprienSdk ApprienManager:testPackageName integrationType:appleIntegration token:token];
        const ApprienIntegrationType resultIntegrationType = apprienSdk.integrationType;
        XCTAssertTrue(resultIntegrationType == appleIntegration);
    }
}

//Quick test to check that the api returns nstrings and they have base url in it.
- (void)testApprienReturnUrls {
    @autoreleasepool {
        NSString *baseUrl = @"https://";
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
        NSString *baseUrl = @"https://";
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
        NSString *baseUrl = @"https://";
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
    NSString *result = [apprienSdk deviceUniqueIdentifier];
    XCTAssertTrue([result isEqualTo:@""]);
}


- (void)testRequestTimeoutIsNotZeroByDefault {
    int result = [apprienSdk REQUEST_TIMEOUT];
    XCTAssertTrue(result != 0);
}

- (void)testFetchingManyProductsShouldSucceed {

    NSArray *expectedVariantIdPart = @[@"apprien", @"apprien", @"test_product_3_sku", @"test_subscription_03", @"apprien"];

    BOOL isDone = [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
    }];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.1, false);
    //wait for async to complete
    while (!isDone) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [products count]; i++) {
        ApprienProduct *product = products[i];
        NSString *expectedStringToBeFound = expectedVariantIdPart[i];
        //IOS7 compatible way of checking if string contains some other string
        XCTAssertTrue([product.apprienVariantIAPId rangeOfString:expectedStringToBeFound].location != NSNotFound);
    }
}


- (void)testFetchingProductsWithBadURLShouldFail {

    apprienSdk.REST_GET_ALL_PRICES_URL = [[@"http://localhost:" stringByAppendingString:@"123123"] stringByAppendingString:@"/api/v0/stores/google/games/{0}/products/{1}/prices"];

    NSArray *expectedVariantIdPart = [[NSArray alloc] initWithArray:products];

    BOOL isDone = [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
    }];
    //wait for async to complete
    while (!isDone) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [products count]; i++) {
        ApprienProduct *product = products[i];
        ApprienProduct *expectedStringToBeFound = expectedVariantIdPart[i];
        XCTAssertEqual(product.apprienVariantIAPId, expectedStringToBeFound.apprienVariantIAPId);
    }
}

- (void)testFetchingProductsWithBadTokenShouldNotFetchVariants {

    [apprienSdk setToken:@"badToken"];
    NSArray *expectedVariantIdPart = [[NSArray alloc] initWithArray:products];

    BOOL isDone = [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
    }];
    //wait for async to complete
    while (!isDone) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }

    for (int i = 0; i < [products count]; i++) {
        ApprienProduct *product = products[i];
        ApprienProduct *expectedStringToBeFound = expectedVariantIdPart[i];
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

    BOOL isDone = [apprienSdk FetchApprienPrices:products callback:^(NSArray *productsWithPrices) {
        products = productsWithPrices;
    }];

    //wait for async to complete
    while (!isDone) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    }
    for (int i = 0; i < [products count]; i++) {
        ApprienProduct *product = products[i];
        ApprienProduct *expectedStringToBeFound = expectedVariantIdPart[i];
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

/*TODO:Ask how to to test this?
- (void)testProductsShown {
    BOOL isDone = [apprienSdk ProductsShown:products];
    while (isDone == FALSE) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
    }

    for (int i = 0; i < [products count]; i++) {
        ApprienProduct *product = products[i];
        NSString *expectedIapId = [testIAPids[i] stringByAppendingString:@"-variant"];
        NSString *resultId = product.apprienVariantIAPId;
        XCTAssertEqual(expectedIapId, resultId);
    }
}
*/

- (void)testGetBaseIAPId {
    NSString *baseIapId = [apprienSdk GetBaseIAPId:defaultIAPid];
    XCTAssertTrue([baseIapId rangeOfString:@"test"].location != NSNotFound);

    baseIapId = [apprienSdk GetBaseIAPId:@"z_test.apprien_sku"];
    NSString *expectedRsult = @"test";
    XCTAssertTrue([baseIapId rangeOfString:@"test"].location != NSNotFound);
}

//Test against the real Apprien service. If these fail the server is most likely down.
- (void)testConnection {
    if ([apprienSdk TestConnection] == TRUE) {
        //Connection to Apprien up
        XCTAssertTrue(TRUE);
    } else {
        //Connection to Apprien down
        XCTAssertTrue(FALSE);
    }
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
}

- (void)testTokenValidity {
    if ([apprienSdk CheckTokenValidity] == TRUE) {
        //Success
        XCTAssertTrue(TRUE);
    } else {
        //Fail
        XCTAssertTrue(FALSE);
    }
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.25, false);
}

//Test Apprien service
- (void)testApprienServiceStatus {
    
    if ([apprienSdk CheckServiceStatus] == TRUE) {
        //Success
        XCTAssertTrue(TRUE);
    } else {
        //Fail
        XCTAssertTrue(FALSE);
    }
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
}
@end
