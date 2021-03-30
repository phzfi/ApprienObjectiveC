/*!
 @header Apprien objective-c port
 @copyright PHZ full stack oy
 @updated 10.3.2021.
 @meta http-equiv=”refresh” content=”0;http://www.phz.fi”
 */
#import <Foundation/Foundation.h>

@class ApprienProduct;//needed for getting apprien products in api calls.

/*!
 @abstract Used to tell Apprien which shop to use.
*/
typedef enum ApprienIntegrationType : NSUInteger {
    GooglePlayStore = 0,
    AppleAppStore = 1
} ApprienIntegrationType;

/*!
 @interface ApprienProduct
 @abstract Interface used to access Apprien.
 @discussion The objective-c version Uses c++ version at its core. It has some changes to make a better integration
 with xcode and to make it easier for user.
*/
@interface ApprienSdk : NSObject

/*!
 @abstract The package name for the game. Usually Application.identifier.
*/
@property(nonatomic) NSString *gamePackageName;

/*!
 @abstract A unique device identifier. It is guaranteed to be unique for every device.
*/
@property(nonatomic) NSString *deviceUniqueIdentifier;

/*!
 @abstract OAuth2 token received from Apprien Dashboard.
*/
@property(nonatomic) NSString *token;

/*!
 @abstract Define the store ApprienManager should integrate against, e.g. GooglePlayStore
*/
- (int)integrationType;

/*!
 @abstract Request timeout in seconds
*/
@property(nonatomic) int REQUEST_TIMEOUT;

/*!
 @abstract Apprien REST API endpoint for testing the availability of the service
*/
- (NSString *)REST_GET_APPRIEN_STATUS;

/*!
 @abstract Apprien REST API endpoint for testing the validity of the given token
*/
- (NSString *)REST_GET_VALIDATE_TOKEN_URL;

/*!
 @abstract Apprien REST API endpoint for fetching all optimum product variants
*/
@property(nonatomic) NSString *REST_GET_ALL_PRICES_URL;

/*!
 @abstract Apprien REST API endpoint for fetching the optimum product variant for a single product
*/
@property(nonatomic) NSString *REST_GET_PRICE_URL;

/*!
 @abstract Apprien REST API endpoint for POSTing the receipt json for successful transactions
*/
- (NSString *)REST_POST_RECEIPT_URL;

/*!
 @abstract Apprien REST API endpoint for POSTing the receipt json for successful transactions
*/
- (NSString *)REST_POST_ERROR_URL;

/*!
 @abstract Apprien REST API endpoint for POSTing a notice to Apprien that product was shown.
*/
- (NSString *)REST_POST_PRODUCTS_SHOWN_URL;

/*!
 @abstract Gets the store's string identifier for the currently set ApprienIntegrationType
*/
- (NSString *)StoreIdentifier;

/*!
 @abstract Returns the first byte of MD5-hashed DeviceUniqueIdentifier as string (two symbols).
 The identifier is sent to Apprien Game API when feching proces.
*/
@property(nonatomic) NSString *ApprienIdentifier;

/*!
 @abstract Fetch all Apprien variant IAP ids with optimum prices.
 @discussion Prices are located in the Apprien -generated IAP id variants.
 Typically the actual prices are fetched from the Store (Google or Apple) by the StoreManager by providing the IAP id (or in this case the variant).
 @param apprienProducts array of products to be used as container.
 @param callback that is called when all product variant requests have completed. It returns array of apprienProducts
 that contain variant ids. From these can the prices be extracted.
 @return BOOL isDone is returned after the request has been completed.
 */
- (BOOL)FetchApprienPrices:(NSArray *)apprienProducts callback:(void (^)(NSArray <ApprienProduct *> *productsWithPrices))callback;

/*!
 @abstract Initializes a new instance of the ApprienManager
 @param gamePackageName The package name of the game. Usually Application.identifier
 @param integrationType Store integration, e.g. GooglePlayStore, AppleAppStore.
 @param token Token, retrieved from the Apprien Dashboard.
*/
- (void)ApprienManager:(NSString *)gamePackageName integrationType:(int)integrationType token:(NSString *)token;

/*!
 @abstract  Perform an availability check for the Apprien service and test the validity of the OAuth2 token.
*/
- (BOOL)TestConnection;

/*!
 @abstract Check whether Apprien API service is online.
*/
- (BOOL)CheckServiceStatus;

/*!
 @abstract Validates the supplied access token with the Apprien API
*/
- (void)CheckTokenValidity:(void (^)(BOOL tokenIsValid))callback;

/*!
 @abstract Posts the receipt to Apprien for calculating new prices.
 @discussion Uses REST_POST_RECEIPT_URL as address
 @param receiptJson NSString containing the receipt for the form to be posted.
*/
+ (BOOL)PostReceipt:(NSString *)receiptJson;

/*!
 @abstract Tell Apprien that these products were shown. NOTE: This is needed for Apprien to work correctly.
*/
- (BOOL)ProductsShown:(NSArray<ApprienProduct *> *)apprienProducts;

/*!
 @abstract Parses the base IAP id from the Apprien response (variant IAP id)
 @discussion Variant IAP id is e.g. "z_base_iap_id.apprien_500_dfa3", where
 - the prefix is z_ (2 characters) to sort the IAP ids on store listing to then end
 - followed by the base IAP id that can be parsed by splitting the string by the separator ".apprien_"
 - followed by the price in cents
 - followed by 4 character hash
 @param storeIAPId Apprien product IAP id on the Store (Google or Apple) e.g. z_pack2_gold.apprien_399_abcd
 @return Returns the base IAP id for the given Apprien variant IAP id.
*/
- (NSString *)GetBaseIAPId:(NSString *)storeIAPId;
@end
