//
// Created by phz on 25.2.2021.
//

#import "IapProduct.h"


@implementation IapProduct
@synthesize baseIAPId;
@synthesize apprienVariantIAPId;
@synthesize store;

- (instancetype)init {
    self = [super init];
    baseIAPId = @"";
    apprienVariantIAPId = @"";
    store = @"";
    return self;
}

- (instancetype)initWithBaseIapId:(NSString *)baseIapIdIn {
    self = [super init];
    baseIAPId = baseIapIdIn;
    // Defaults the variant name to the base IAP id. FetchApprienPrice will replace this if fetch succeeds
    apprienVariantIAPId = baseIapIdIn;
    return self;
}

- (IapProduct *)ApprienProduct:(NSString *)baseIapIdIn {
    IapProduct *aP = [[IapProduct alloc] init];
    aP.baseIAPId = baseIapIdIn;
    // Defaults the variant name to the base IAP id. FetchApprienPrice will replace this if fetch succeeds
    aP.apprienVariantIAPId = baseIapIdIn;
    return aP;
}

- (NSMutableArray *)FromIAPCatalog:(NSArray<NSString *> *)catalog {
    int count = (int) [catalog count];
    NSMutableArray *apprienProducts = [[NSMutableArray alloc] init];

    for (int i = 0; i < count; ++i) {
        [apprienProducts addObject:[self ApprienProduct:catalog[i]]];
    }

    return apprienProducts;
}


@end
