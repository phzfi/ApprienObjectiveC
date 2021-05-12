//
//  ApprienSdk.m
//  apprien-objective-c-sdk
//
//  Created by phz on 22.2.2021.
//

#import "ApprienSdk.h"
#import "Apprien.h"
#import "ApprienProduct.h"

@implementation ApprienSdk : NSObject
@synthesize DEBUGGING_ENABLED;
@synthesize REQUEST_TIMEOUT;
@synthesize REST_GET_PRICE_URL;
@synthesize REST_GET_ALL_PRICES_URL;
@synthesize REST_GET_VALIDATE_TOKEN_URL;
@synthesize REST_POST_RECEIPT_URL;
@synthesize REST_POST_PRODUCTS_SHOWN_URL;
@synthesize IntegrationType;

NSURLSession *sessionWithoutADelegate;
Apprien::ApprienManager *apprienManager;
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
         integrationTypes =  [NSArray arrayWithObjects: @"google", @"apple", nil];
     }
     return self;
}

- (void)ApprienManager:(NSString *)gamePackageName integrationType:(NSInteger *) integrationType token:(NSString *)token {
    self.gamePackageName = gamePackageName;
    self.integrationType = integrationType;
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
    return integrationTypes[self.IntegrationType];
}


- (NSString *)ApprienIdentifier {
    return [NSString stringWithCString:apprienManager->ApprienIdentifier().c_str()
                              encoding:[NSString defaultCStringEncoding]];
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
    NSMutableURLRequest * requestTask = request.Get(apprienManager->REST_GET_APPRIEN_STATUS);

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

- (std::vector<Apprien::ApprienManager::ApprienProduct> &)CopyApprienProductsFromObjCToCPP:(NSArray *)apprienProducts apprienProductsC:(std::vector<Apprien::ApprienManager::ApprienProduct> &)apprienProductsC {
    @autoreleasepool {
        int size = (int) [apprienProducts count];
        for (int i = 0; i < size; i++) {
            Apprien::ApprienManager::ApprienProduct apprienProduct;
            ApprienProduct *p = apprienProducts[i];
            apprienProduct.store = p.store.UTF8String;
            apprienProduct.baseIAPId = p.baseIAPId.UTF8String;
            apprienProduct.apprienVariantIAPId = p.apprienVariantIAPId.UTF8String;
            apprienProductsC.push_back(apprienProduct);
        }
        return apprienProductsC;
    }
}

- (NSMutableArray *)CopyApprienProductsFromCPPToObjC:(const std::vector<Apprien::ApprienManager::ApprienProduct> &)apprienProductsC {
    @autoreleasepool {
        int size = (int)sizeof(apprienProductsC)/sizeof(apprienProductsC[0]);
        NSMutableArray<ApprienProduct*> *apprienProducts = [[NSMutableArray<ApprienProduct*> alloc]init];
        for (int i = 0; i < size; i++) {
            ApprienProduct *product =  [[ApprienProduct alloc]init];
            product.store = [NSString stringWithCString:apprienProductsC[i].store.c_str() encoding:[NSString defaultCStringEncoding]];
            product.baseIAPId = [NSString stringWithCString:apprienProductsC[i].baseIAPId.c_str() encoding:[NSString defaultCStringEncoding]];
            product.apprienVariantIAPId = [NSString stringWithCString:apprienProductsC[i].apprienVariantIAPId.c_str() encoding:[NSString defaultCStringEncoding]];
            [apprienProducts addObject:product];
        }
        return apprienProducts;
    }
}

@end
