//
//  ApprienSdk.m
//  apprien-objective-c-sdk
//
//  Created by phz on 22.2.2021.
//

#import "ApprienSdk.h"
#import "IapProduct.h"
#import <CommonCrypto/CommonDigest.h>
#import "FormDataSection.h"
#import "WebRequest.h"
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
         self.REST_GET_PRICE_URL = @"http://game.apprien.com/api/v0/stores/%s/games/%s/products/%s/prices";
         self.REST_GET_ALL_PRICES_URL = @"http://game.apprien.com/api/v0/stores/%s/games/%s/prices";
         self.REST_GET_VALIDATE_TOKEN_URL = @"http://game.apprien.com/api/v1/stores/%s/games/%s/auth";
         self.REST_GET_APPRIEN_STATUS = @"http://game.apprien.com/status";
         self.REST_POST_ERROR_URL = @"http://game.apprien.com/error?message=%s&responseCode=%s&storeGame=%s&store=%s";
         self.REST_POST_RECEIPT_URL = @"http://game.apprien.com/api/v0/stores/%s/games/%s/receipts";
         self.REST_POST_PRODUCTS_SHOWN_URL = @"http://game.apprien.com/api/v1/stores/%s/shown/products";
         self.DeviceUniqueIdentifier = @"";
         integrationTypes =  [NSArray arrayWithObjects: @"google", @"apple", nil];
     }
     return self;
}

-(ApprienSdk *)initWithGamePackage:(NSString *)gamePackageName integrationType:(ApprienIntegrationType) integrationType token:(NSString *)token {
     if (self = [super init])  {
       self.REQUEST_TIMEOUT = 10;
         self.REST_GET_PRICE_URL = @"http://game.apprien.com/api/v0/stores/%s/games/%s/products/%s/prices";
         self.REST_GET_ALL_PRICES_URL = @"http://game.apprien.com/api/v0/stores/%s/games/%s/prices";
         self.REST_GET_VALIDATE_TOKEN_URL = @"http://game.apprien.com/api/v1/stores/%s/games/%s/auth";
         self.REST_GET_APPRIEN_STATUS = @"http://game.apprien.com/status";
         self.REST_POST_ERROR_URL = @"http://game.apprien.com/error?message=%s&responseCode=%s&storeGame=%s&store=%s";
         self.REST_POST_RECEIPT_URL = @"http://game.apprien.com/api/v0/stores/%s/games/%s/receipts";
         self.REST_POST_PRODUCTS_SHOWN_URL = @"http://game.apprien.com/api/v1/stores/%s/shown/products";
         self.DeviceUniqueIdentifier = @"";
         integrationTypes =  [NSArray arrayWithObjects: @"google", @"apple", nil];
         self.gamePackageName = gamePackageName;
         self.IntegrationType = integrationType;
         self.token = token;
     }
     return self;
}

- (ApprienIntegrationType)getIntegrationType {
    return IntegrationType;
}

- (NSString *)deviceUniqueIdentifier {
    return DeviceUniqueIdentifier;
}

- (NSString *)StoreIdentifier {
    return [integrationTypes objectAtIndex: (NSUInteger)self.IntegrationType];
}

- (NSString *)ApprienIdentifier {
    //TODO: aprrien identifier and device unique identifier
    return nil;//[self.sha256HashFor self.DeviceUniqueIdentifier];
}

-(NSString*)sha256HashFor:(NSString*)input
{
    NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *sha256Data = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
   // CC_SHA256([data bytes], (CC_LONG)[data length], [sha256Data mutableBytes]);
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
    WebRequest *request = [[WebRequest alloc] init];
    NSMutableURLRequest * requestTask = [request Get: self.REST_GET_APPRIEN_STATUS];

    [[[request GetSession] dataTaskWithRequest:requestTask completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if([self DEBUGGING_ENABLED]){
            NSLog(@"Got response %@ with error %@.\n", response, error);
            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        if([request HandleResponse: response error: error] == 200){
            callback(true);
        }
        else{
            callback(false);
        }
    }] resume];
}

-(NSString *) BuildUrl:(NSString*) address{
    
    NSString *url = [[NSString alloc] init];
    url =[url stringByAppendingString:address];
    url =[url stringByAppendingString:self.StoreIdentifier];
    url =[url stringByAppendingString:self.gamePackageName];
    return url;
}

- (void)CheckTokenValidity:(void (^)(BOOL tokenIsValid))callback {

    WebRequest *request = [[WebRequest alloc] init];
    NSMutableURLRequest *requestTask = [request Get:[self BuildUrl:self.REST_GET_VALIDATE_TOKEN_URL]];
    NSString *headerValue =[@"Bearer " stringByAppendingString:[self token]];
    [request SetRequestHeader:@"Authorization:" value: headerValue];
    [request SetRequestHeader:@"Session-Id" value: [self ApprienIdentifier]];
    
    [[[request GetSession] dataTaskWithRequest:requestTask completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if([self DEBUGGING_ENABLED]){
            NSLog(@"Got response %@ with error %@.\n", response, error);
            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        if([request HandleResponse: response error: error] == 0){
            callback(true);
        }
        else{
            callback(false);
        }
    }] resume];
}

- (void)PostReceipt:(NSString *)receiptJson completionHandler: (void (^)())completionHandler {
/*
    apprienManager->PostReceipt([receiptJson UTF8String], ^(int response, int error){
        completionHandler();
    });*/
}

- (void)ProductsShown:(NSArray<IapProduct *> *)apprienProducts completionHandler: (void (^)())completionHandler{
    @autoreleasepool {
       /* NSArray<FormDataSection*> *formData = [[NSArray<FormDataSection*> alloc ]  init];
        for [[(unsigned int i = 0; i < [apprienProducts length]; i++) {
            std::ostringstream oss;
            oss << "iap_ids[" << i << "]";
            formData.insert(it, FormDataSection(oss.str(), apprienProducts[i].apprienVariantIAPId.c_str()));
        }

        char url[5000];
        WebRequest request = [WebRequest alloc] init];
        snprintf(url, sizeof(url), REST_POST_PRODUCTS_SHOWN_URL, StoreIdentifier().c_str());
        request.Post(url, formData, callback);
        request.SetRequestHeader("Authorization:", "Bearer " + token);
        request.SendWebRequest();

        if (request.responseCode != 0) {
            SendError(request.responseCode, "Error occured while posting products shown: HTTP error: " + request.errorMessage);
        }*/
    }
}

- (NSString *)GetBaseIAPId:(NSString *)storeIapId {
    // Default result to (base) storeIapId
    NSString *result = storeIapId;

    // First check if this is a variant IAP id or base IAP id
    NSUInteger location = [result rangeOfString:@".apprien_"].location;
    if (location != NSNotFound) {
        // Get the base IAP id part, remove the suffix
        result=  [result substringWithRange:NSMakeRange(0, location)];

        // Remove prefix
        result = [result substringWithRange:NSMakeRange(2, [result length])];
    }
    return result;
}

- (void)FetchApprienPrices:(NSArray <IapProduct *> *)apprienProducts callback:(void (^)(NSArray <IapProduct *> *productsWithPrices))callback {
   
    WebRequest *request = [[WebRequest alloc] init];
    
    NSMutableURLRequest * requestTask = [request Get:[self BuildUrl:REST_GET_ALL_PRICES_URL]];
   
    NSString *headerValue =[@"Bearer:" stringByAppendingString:[self token]];
    [request SetRequestHeader:@"Authorization " value: headerValue];
    [request SetRequestHeader:@"Session-Id" value: [self ApprienIdentifier]];
    [[[request GetSession] dataTaskWithRequest:requestTask completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if([self DEBUGGING_ENABLED]){
            NSLog(@"Got response %@ with error %@.\n", response, error);
            NSLog(@"DATA:\n%@\nEND DATA\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }

        if(error){
           //TODO: handle error sending
        }
        
        NSMutableArray<IapProduct*> *apprienProductsOut = [self CopyApprienProductsFromData:data];
        if([apprienProductsOut count] == 0){
            callback(apprienProducts);
        }
        else{
            callback(apprienProductsOut);
        }
    }] resume];
}

- (NSMutableArray<IapProduct*> *)CopyApprienProductsFromData: (NSData *) data{
    @autoreleasepool {
        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        NSMutableArray<IapProduct*> *products = [self GetProducts:data];
        
        return products;
    }
}

/// <summary>
/// Parse the JSON data and update the variant IAP ids.
/// </summary>
-(NSMutableArray<IapProduct*>*) GetProducts: (NSData *)data {
    NSArray<IapProduct*> *products = [[NSArray alloc] init];
   
        //products = [self ParseJSON: data];
        
        /*for (ApprienProduct *product in products) {
 
                if (product.base == products[i].baseIAPId) {
                    products[i].baseIAPId = product.base;
                    products[i].apprienVariantIAPId = product.variant;
                }
        }*/
    

    return products;
}

-(NSDictionary *) ParseJSON:(NSData *)data {
    if(NSClassFromString(@"NSJSONSerialization"))
    {
        NSError *error = nil;
        id object = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:0
                          error:&error];

        if(error) { /* JSON was malformed, act appropriately here */ }

        // the originating poster wants to deal with dictionaries;
        // assuming you do too then something like this is the first
        // validation step:
        if([object isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *results = object;
            /* proceed with results as you like; the assignment to
            an explicit NSDictionary * is artificial step to get
            compile-time checking from here on down (and better autocompletion
            when editing). You could have just made object an NSDictionary *
            in the first place but stylistically you might prefer to keep
            the question of type open until it's confirmed */
            return object;
        }
        else
        {
            /* there's no guarantee that the outermost object in a JSON
            packet will be a dictionary; if we get here then it wasn't,
            so 'object' shouldn't be treated as an NSDictionary; probably
            you need to report a suitable error condition */
            //TODO: report error
            return nil;
        }
       
    }
    return nil;
}
@end
