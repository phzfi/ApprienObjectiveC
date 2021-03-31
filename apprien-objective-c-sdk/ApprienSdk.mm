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

@synthesize token;
@synthesize REQUEST_TIMEOUT;
@synthesize REST_GET_PRICE_URL;
@synthesize REST_GET_ALL_PRICES_URL;

Apprien::ApprienManager *apprienManager;

- (void)ApprienManager:(NSString *)gamePackageName integrationType:(int)integrationType token:(NSString *)token {
    apprienManager = new Apprien::ApprienManager([gamePackageName UTF8String], static_cast<Apprien::ApprienIntegrationType>(integrationType), [token UTF8String]);
}

- (NSString *)gamePackageName {
    return [NSString stringWithCString:apprienManager->gamePackageName.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (NSString *)deviceUniqueIdentifier {
    return [NSString stringWithCString:apprienManager->deviceUniqueIdentifier.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}


- (NSString *)token {
    return [NSString stringWithCString:apprienManager->token.c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (void)setToken:(NSString *)newToken {
    apprienManager->token = newToken.UTF8String;
}

- (int)REQUEST_TIMEOUT {
    return apprienManager->REQUEST_TIMEOUT;
}

- (void)setREQUEST_TIMEOUT:(int)newREQUEST_TIMEOUT {
    apprienManager->REQUEST_TIMEOUT = newREQUEST_TIMEOUT;
}

- (NSString *)REST_GET_PRICE_URL {
    return [NSString stringWithUTF8String:apprienManager->REST_GET_PRICE_URL];
}

- (void)setREST_GET_PRICE_URL:(NSString *)new_REST_GET_PRICE_URL {
    apprienManager->REST_GET_PRICE_URL = new_REST_GET_PRICE_URL.UTF8String;
}

- (NSString *)REST_GET_ALL_PRICES_URL {
    return [NSString stringWithUTF8String:apprienManager->REST_GET_ALL_PRICES_URL];
}

- (void)setREST_GET_ALL_PRICES_URL:(NSString *)new_REST_GET_ALL_PRICE_URL {
    apprienManager->REST_GET_ALL_PRICES_URL = new_REST_GET_ALL_PRICE_URL.UTF8String;
}

- (int)integrationType {
    return static_cast<int>(apprienManager->integrationType);
}

- (NSString *)REST_GET_APPRIEN_STATUS {
    return [NSString stringWithUTF8String:apprienManager->REST_GET_APPRIEN_STATUS];
}

- (NSString *)REST_GET_VALIDATE_TOKEN_URL {
    return [NSString stringWithUTF8String:apprienManager->REST_GET_VALIDATE_TOKEN_URL];
}

- (NSString *)REST_POST_RECEIPT_URL {
    return [NSString stringWithUTF8String:apprienManager->REST_POST_RECEIPT_URL];
}

- (NSString *)REST_POST_ERROR_URL {
    return [NSString stringWithUTF8String:apprienManager->REST_POST_ERROR_URL];
}

- (NSString *)REST_POST_PRODUCTS_SHOWN_URL {
    return [NSString stringWithUTF8String:apprienManager->REST_POST_PRODUCTS_SHOWN_URL];
}

- (NSString *)StoreIdentifier {
    return [NSString stringWithCString:apprienManager->StoreIdentifier().c_str()
                              encoding:[NSString defaultCStringEncoding]];
}


- (NSString *)ApprienIdentifier {
    return [NSString stringWithCString:apprienManager->ApprienIdentifier().c_str()
                              encoding:[NSString defaultCStringEncoding]];
}

- (void)TestConnection:(void (^)(BOOL statusCheck, BOOL tokenCheck))completionHandler {
    apprienManager->TestConnection(^(BOOL statusCheck, BOOL tokenCheck){
            completionHandler(statusCheck, tokenCheck);
    });
}

- (void)CheckServiceStatus: (void (^)(BOOL serviceOk))callback {
     apprienManager->CheckServiceStatus(^(int response, int error) {
         if(error == 0 && response == 0){
             callback(true);
         }
         else{
             callback(false);
         }
     });
}

- (void)CheckTokenValidity:(void (^)(BOOL tokenIsValid))callback {
     apprienManager->CheckTokenValidity(^(int response, int error){
         if(error == 0 && response == 0){
             callback(true);
         }
         else{
             callback(false);
         }
     });
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
    std::vector<Apprien::ApprienManager::ApprienProduct> apprienProductsC;
    apprienProductsC = [self CopyApprienProductsFromObjCToCPP:apprienProducts apprienProductsC:apprienProductsC];

    apprienManager->FetchApprienPrices(apprienProductsC, ^(std::vector<Apprien::ApprienManager::ApprienProduct> apprienProductsC)
    {
        NSArray <ApprienProduct *> *apprienProductsAndPrices = [self CopyApprienProductsFromCPPToObjC:apprienProducts apprienProductsC:apprienProductsC];

        apprienManager->CatchAndSendRequestError();

        callback(apprienProductsAndPrices);
    });
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

- (NSArray *)CopyApprienProductsFromCPPToObjC:(NSArray *)apprienProducts apprienProductsC:(const std::vector<Apprien::ApprienManager::ApprienProduct> &)apprienProductsC {
    @autoreleasepool {
        int size = (int) [apprienProducts count];
        for (int i = 0; i < size; i++) {
            ApprienProduct *product = [apprienProducts objectAtIndex:i];
            product.store = [NSString stringWithCString:apprienProductsC[i].store.c_str() encoding:[NSString defaultCStringEncoding]];
            product.baseIAPId = [NSString stringWithCString:apprienProductsC[i].baseIAPId.c_str() encoding:[NSString defaultCStringEncoding]];
            product.apprienVariantIAPId = [NSString stringWithCString:apprienProductsC[i].apprienVariantIAPId.c_str() encoding:[NSString defaultCStringEncoding]];
        }
        return apprienProducts;
    }
}

@end
