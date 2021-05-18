//
// Created by phz on 25.2.2021.
// This is a replacement for the cpp ApprienProduct object in Apprien.h
// This is needed for better integration, because the api cannot have cpp specific objects on it. Otherwise
// The client user would need to compile their code with non standard compiler making the plugin ard to use


#import <Foundation/Foundation.h>


@interface IapProduct : NSObject

/// <summary>
/// The base product id. Apprien will fallback to this id if a variant cannot be retrieved.
/// </summary>
@property NSString *baseIAPId;

/// <summary>
/// Apprien creates variants of the base IAP id, e.g.
/// z_iapBaseName.apprien_1990_v34f
/// where 1990 is e.g. 1990 USD cents and the last 4 symbols are a unique hash.
/// The variants start with "z_" to sort them last and distiguish them
/// easily from the base IAP ids
/// </summary>
@property NSString *apprienVariantIAPId;

/// <summary>
/// Optional. If defined, the IAPId only applies to the given store. If this product exists in multiple stores,
/// multiple ApprienProduct objects are required.
/// The string is identifier for stores, e.g. "AppleAppStore", "GooglePlay" etc.
/// </summary>
@property NSString *store;

- (instancetype)initWithBaseIapId:(NSString *)baseIapIdIn;

/// <summary>
/// Convert a products into ApprienProduct objects ready for fetching Apprien prices.
/// Does not alter the catalog
/// </summary>
/// <param name="catalog"></param>
/// <returns>Returns an array of Apprien Products built from the given ProductCatalog object</returns>

- (NSMutableArray *)FromIAPCatalog:(NSArray<NSString *> *)products;

@end
