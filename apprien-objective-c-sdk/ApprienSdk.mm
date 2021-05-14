//
//  ApprienSdk.m
//  apprien-objective-c-sdk
//
//  Created by phz on 22.2.2021.
//

#import "ApprienSdk.h"
#import "ApprienProduct.h"
#import <CommonCrypto/CommonDigest.h>

@implementation ApprienSdk : NSObject
@synthesize DEBUGGING_ENABLED;
@synthesize REQUEST_TIMEOUT;
@synthesize REST_GET_PRICE_URL;
@synthesize REST_GET_ALL_PRICES_URL;
@synthesize REST_GET_VALIDATE_TOKEN_URL;
@synthesize REST_POST_RECEIPT_URL;
@synthesize REST_POST_PRODUCTS_SHOWN_URL;
@synthesize IntegrationType;
@synthesize DeviceUniqueIdentifier;

NSURLSession *sessionWithoutADelegate;
NSArray *integrationTypes;

-(id)init {
     if (self = [super init])  {
       self.REQUEST_TIMEOUT = 10;
         self.REST_GET_PRICE_URL = @"http://game.apprien.com/api/v1/stores/%s/games/%s/products/%s/prices";
         self.REST_GET_ALL_PRICES_URL = @"http://game.apprien.com/api/v1/stores/%s/games/%s/prices";
         self.REST_GET_VALIDATE_TOKEN_URL = @"http://game.apprien.com/api/v1/stores/%s/games/%s/auth";
         self.REST_GET_APPRIEN_STATUS = @"http://game.apprien.com/status";
         self.REST_POST_ERROR_URL = @"http://game.apprien.com/error?message=%s&responseCode=%s&storeGame=%s&store=%s";
         self.REST_POST_RECEIPT_URL = @"http://game.apprien.com/api/v1/stores/%s/games/%s/receipts";
         self.REST_POST_PRODUCTS_SHOWN_URL = @"http://game.apprien.com/api/v1/stores/%s/shown/products";
         self.DeviceUniqueIdentifier = @"";
         integrationTypes =  [NSArray arrayWithObjects: @"google", @"apple", nil];
     }
     return self;
}

- (void)ApprienManager:(NSString *)gamePackageName integrationType:(NSUInteger *) integrationType token:(NSString *)token {
    self.gamePackageName = gamePackageName;
    self.IntegrationType = integrationType;
    self.token = token;
}

- (NSString *)deviceUniqueIdentifier {
    return [NSString stringWithCString:apprienManager->deviceUniqueIdentifier.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (int)REQUEST_TIMEOUT {
    return REQUEST_TIMEOUT;
}

- (void)setREQUEST_TIMEOUT:(int)newREQUEST_TIMEOUT {
    REQUEST_TIMEOUT = newREQUEST_TIMEOUT;
}


- (NSString *)StoreIdentifier {
    return [integrationTypes objectAtIndex: (NSUInteger)self.IntegrationType];
}

- (NSString *)ApprienIdentifier {
    //TODO: aprrien identifier and device unique identifier
    return [self.sha256HashFor self.DeviceUniqueIdentifier];
}

-(NSString*)sha256HashFor:(NSString*)input
{
    NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *sha256Data = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([data bytes], (CC_LONG)[data length], [sha256Data mutableBytes]);
    return [sha256Data base64EncodedStringWithOptions:0];
}

-(NSString*)Sha256HashForText:(NSString*)text {
    const char* utf8chars = [text UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(utf8chars, (CC_LONG)strlen(utf8chars), result);

    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for(int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}


- (void)TestConnection:(void (^)(BOOL statusCheck, BOOL tokenCheck))callback {

    [self CheckServiceStatus:^(BOOL serviceIsOk) {

        [self CheckTokenValidity: ^(BOOL tokenIsValid) {
            callback(serviceIsOk, tokenIsValid);
        }];
    }];
}

- (void)CheckServiceStatus: (void (^)(BOOL serviceOk))callback {
    auto request = WebRequest();
    NSMutableURLRequest * requestTask = request.Get(self.REST_GET_APPRIEN_STATUS);

    [[request.GetSession() dataTaskWithRequest:requestTask completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if([self DEBUGGING_ENABLED]){
            NSLog(@"Got response %@ with error %@.\n", response, error);
            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        if(request.HandleResponse(response, error) == 200){
            callback(true);
        }
        else{
            callback(false);
        }
    }] resume];
}

- (void)CheckTokenValidity:(void (^)(BOOL tokenIsValid))callback {

    auto request = WebRequest();
    NSMutableURLRequest * requestTask = request.Get(apprienManager->BuildUrl(apprienManager->REST_GET_VALIDATE_TOKEN_URL));
    NSString *headerValue =[@"Bearer " stringByAppendingString:[self token]];
    request.SetRequestHeader(@"Authorization:" , headerValue);
    request.SetRequestHeader(@"Session-Id", [self ApprienIdentifier]);
    
    [[request.GetSession() dataTaskWithRequest:requestTask completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if([self DEBUGGING_ENABLED]){
            NSLog(@"Got response %@ with error %@.\n", response, error);
            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        if(request.HandleResponse(response, error) == 0){
            callback(true);
        }
        else{
            callback(false);
        }
    }] resume];
}

- (void)PostReceipt:(NSString *)receiptJson completionHandler: (void (^)())completionHandler {

    apprienManager->PostReceipt([receiptJson UTF8String], ^(int response, int error){
        completionHandler();
    });
}

- (void)ProductsShown:(NSArray<ApprienProduct *> *)apprienProducts completionHandler: (void (^)())completionHandler{
    @autoreleasepool {
        std::vector<Apprien::ApprienManager::ApprienProduct> apprienProductsCPP;
        [self CopyApprienProductsFromObjCToCPP:apprienProducts apprienProductsC:apprienProductsCPP];
        apprienManager->ProductsShown(apprienProductsCPP, ^(int response, int error) {
            completionHandler();
        });
    }
}

- (NSString *)GetBaseIAPId:(NSString *)storeIapId {
    return [NSString stringWithCString:apprienManager->GetBaseIAPId(storeIapId.UTF8String).c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (void)FetchApprienPrices:(NSArray <ApprienProduct *> *)apprienProducts callback:(void (^)(NSArray <ApprienProduct *> *productsWithPrices))callback {
   
    auto request = WebRequest();
    
    NSMutableURLRequest * requestTask = request.Get(apprienManager->BuildUrl(apprienManager->REST_GET_ALL_PRICES_URL));
   
    NSString *headerValue =[@"Bearer:" stringByAppendingString:[self token]];
    request.SetRequestHeader(@"Authorization " , headerValue);
    request.SetRequestHeader(@"Session-Id", [self ApprienIdentifier]);
    [[request.GetSession() dataTaskWithRequest:requestTask completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if([self DEBUGGING_ENABLED]){
            NSLog(@"Got response %@ with error %@.\n", response, error);
            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        if(error){
           //TODO: handle error sending
        }
        
        NSMutableArray<ApprienProduct*> *apprienProductsOut = [self CopyApprienProductsFromData:data];
        if([apprienProductsOut count] == 0){
            callback(apprienProducts);
        }
        else{
            callback(apprienProductsOut);
        }
    }] resume];
}

- (NSMutableArray<ApprienProduct*> *)CopyApprienProductsFromData: (NSData *) data{
    @autoreleasepool {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        char *dataIn =const_cast<char *>(dataString.UTF8String);
        std::vector<Apprien::ApprienManager::ApprienProduct> products = apprienManager->GetProducts(dataIn);
        
        return [self CopyApprienProductsFromCPPToObjC:products];
    }
}
@end
