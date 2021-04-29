#pragma once

#include "WebRequest.h"

#include <list>
#include <vector>
#include <map>

/// <summary>
/// <para>
/// Apprien SDK to optimize IAP prices.
/// </para>
/// <para>
/// Class Apprien is Plain-old-CPP-object -client to the Apprien REST API.
/// </para>
/// <para>
/// Apprien is an automated priciApprien::ApprienManager::ApprienProductenManager::ApprienProduct calculates the optimum**
/// prices by every 15mins in each country. We can typically increase the
/// revenue and Life Time Value of the game by 20-40%, which makes it easier
/// to:
/// 1) acquire more users (spend the money to User Acquisition)
/// 2) find publishers or financiers
/// 3) take it easy :)
/// </para>
/// <para>
/// See more from https://www.apprien.com
/// API Documentation on https://game.apprien.com
/// </para>
/// </summary>
namespace Apprien {
    /// <summary>
    /// Defines the available integrations Apprien supports.
    /// </summary>
    enum class ApprienIntegrationType {
        GooglePlayStore = 0,
        AppleAppStore = 1
    };

    class ApprienManager {
    private:
        /// <summary>
        /// Map for mapping store names (in Apprien REST API URLs) to ApprienIntegrationType
        /// </summary>
        std::map<ApprienIntegrationType, std::string> _integrationURI =
                {
                        {ApprienIntegrationType::GooglePlayStore, "google"},
                        {ApprienIntegrationType::AppleAppStore, "apple"}
                };

        /// <summary>
        /// Sends error message when Apprien encounter any problems
        /// </summary>
        /// <param name="responseCode">Http responsecode</param>
        /// <param name="errorMessage">errorMessage changes depending on the error</param>
        void SendError(int responseCode, std::string errorMessage);

    public:
        class ApprienProduct {
        public:
            /// <summary>
            /// The base product id. Apprien will fallback to this id if a variant cannot be retrieved.
            /// </summary>
            std::string baseIAPId;

            /// <summary>
            /// Apprien creates variants of the base IAP id, e.g.
            /// z_iapBaseName.apprien_1990_v34f
            /// where 1990 is e.g. 1990 USD cents and the last 4 symbols are a unique hash.
            /// The variants start with "z_" to sort them last and distiguish them
            /// easily from the base IAP ids
            /// </summary>
            std::string apprienVariantIAPId;

            /// <summary>
            /// Optional. If defined, the IAPId only applies to the given store. If this product exists in multiple stores,
            /// multiple ApprienProduct objects are required.
            /// The string is identifier for stores, e.g. "AppleAppStore", "GooglePlay" etc.
            /// </summary>
            std::string store;

            ApprienProduct() {
                baseIAPId = "";
                apprienVariantIAPId = "";
                store = "";
            }

            ApprienProduct(std::string baseIapId) {
                this->baseIAPId = baseIapId;
                // Defaults the variant name to the base IAP id. FetchApprienPrice will replace this if fetch succeeds
                apprienVariantIAPId = baseIapId;
            }

            /// <summary>
            /// Convert a products into ApprienProduct objects ready for fetching Apprien prices.
            /// Does not alter the catalog
            /// </summary>
            /// <param name="catalog"></param>
            /// <returns>Returns an array of Apprien Products built from the given ProductCatalog object</returns>
            static std::vector<ApprienProduct> FromIAPCatalog(std::vector<std::string> products);
        };

        /// <summary>
        /// The package name for the game. Usually Application.identifier.
        /// </summary>
        std::string gamePackageName;

        /// <summary>
        /// A unique device identifier. It is guaranteed to be unique for every device.
        /// </summary>
        std::string deviceUniqueIdentifier;

        /// <summary>
        /// OAuth2 token received from Apprien Dashboard.
        /// </summary>
        std::string token;

        /// <summary>
        /// Define the store ApprienManager should integrate against, e.g. GooglePlayStore
        /// </summary>
        ApprienIntegrationType integrationType;

        /// <summary>
        /// Request timeout in seconds
        /// </summary>
        int REQUEST_TIMEOUT = 5;
        
        /// <summary>
        /// Sends error message when Apprien encounter any problems
        /// </summary>
        void CatchAndSendRequestError();
        
        /// <summary>
        /// Apprien REST API endpoint for testing the availability of the service
        /// </summary>
        const char *REST_GET_APPRIEN_STATUS = "http://game.apprien.com/status";

        /// <summary>
        /// Apprien REST API endpoint for testing the validity of the given token
        /// </summary>
        const char *REST_GET_VALIDATE_TOKEN_URL = "http://game.apprien.com/api/v1/stores/%s/games/%s/auth";

        /// <summary>
        /// Apprien REST API endpoint for fetching all optimum product variants
        /// </summary>
        const char *REST_GET_ALL_PRICES_URL = "http://game.apprien.com/api/v1/stores/%s/games/%s/prices";

        /// <summary>
        /// Apprien REST API endpoint for fetching the optimum product variant for a single product
        /// </summary>
        const char *REST_GET_PRICE_URL = "http://game.apprien.com/api/v1/stores/%s/games/%s/products/%s/prices";

        /// <summary>
        /// Apprien REST API endpoint for POSTing the receipt json for successful transactions
        /// </summary>
        const char *REST_POST_RECEIPT_URL = "http://game.apprien.com/api/v1/stores/%s/games/%s/receipts";

        /// <summary>
        /// Apprien REST API endpoint for POSTing the receipt json for successful transactions
        /// </summary>
        const char *REST_POST_ERROR_URL = "http://game.apprien.com/error?message=%s&responseCode=%s&storeGame=%s&store=%s";

        /// <summary>
        /// Apprien REST API endpoint for POSTing a notice to Apprien that product was shown.
        /// </summary>
        const char *REST_POST_PRODUCTS_SHOWN_URL = "http://game.apprien.com/api/v1/stores/%s/shown/products";

        /// <summary>
        /// Gets the store's string identifier for the currently set ApprienIntegrationType
        /// </summary>
        std::string StoreIdentifier() {
            return ApprienManager::_integrationURI[integrationType];
        }

        /// <summary>
        /// Returns the first byte of MD5-hashed DeviceUniqueIdentifier as string (two symbols).
        /// The identifier is sent to Apprien Game API
        /// </summary>
        /// <value></value>
        std::string ApprienIdentifier();

        ApprienManager() {
            gamePackageName = "";
            deviceUniqueIdentifier = "";
            token = "";
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="ApprienManager" /> class.
        /// </summary>
        /// <param name="gamePackageName">The package name of the game. Usually Application.identifier</param>
        /// <param name="integrationType">Store integration, e.g. GooglePlayStore, AppleAppStore.</param>
        /// <param name="token">Token, retrieved from the Apprien Dashboard.</param>
        ApprienManager(const char *gamePackageName, ApprienIntegrationType integrationType, const char *token) {
            this->gamePackageName = gamePackageName;
            this->integrationType = integrationType;
            this->token = token;
        }
        
        std::vector<ApprienManager::ApprienProduct> GetProducts(char *data);
        
        /// <summary>
        /// Validates the supplied access token with the Apprien API
        /// </summary>
        void CheckTokenValidity(std::function<void(int response, int errorCode)> callback);
        
        std::string BuildUrl(const char *address);
        
        /// <summary>
        /// <para>
        /// Posts the receipt to Apprien for calculating new prices.
        /// </para>
        /// <para>
        /// Passes messages OnApprienPostReceiptSuccess or OnApprienPostReceiptFailed to the given MonoBehaviour.
        /// </para>
        /// </summary>
        /// <param name="receiptJson"></param>
        void PostReceipt(std::string receiptJson, std::function<void(int response, int errorCode)> callback);

        /// <summary>
        /// Tell Apprien that these products were shown. NOTE: This is needed for Apprien to work correctly.
        /// </summary>
        void ProductsShown(std::vector<ApprienProduct> apprienProducts, std::function<void(int response, int error)> callback );

        /// <summary>
        /// <para>
        /// Parses the base IAP id from the Apprien response (variant IAP id)
        /// </para>
        /// <para>
        /// Variant IAP id is e.g. "z_base_iap_id.apprien_500_dfa3", where
        /// - the prefix is z_ (2 characters) to sort the IAP ids on store listing to then end
        /// - followed by the base IAP id that can be parsed by splitting the string by the separator ".apprien_"
        /// - followed by the price in cents
        /// - followed by 4 character hash
        /// </para>
        /// </summary>
        /// <param name="storeIapId">Apprien product IAP id on the Store (Google or Apple) e.g. z_pack2_gold.apprien_399_abcd</param>
        /// <returns>Returns the base IAP id for the given Apprien variant IAP id.</returns>
        std::string GetBaseIAPId(std::string storeIAPId);

        void CompleteValidateServices(const std::function<void(BOOL, BOOL)> &callback, int response, int error) const;
    };

} // namespace Apprien
