#include "Apprien.h"

using namespace Apprien;

#include "sha256.h"
#include "json.hpp"

using json = nlohmann::json;

class ApprienProductListProduct {
public:
    std::string base;
    std::string variant;
};

void from_json(const json &j, ApprienProductListProduct &sb) {
    sb.base = j["base"].get<std::string>();
    sb.variant = j["variant"].get<std::string>();
}

/// <summary>
/// Product list class used for parsing JSON.
/// </summary>
class ApprienProductList {
public:
    std::list<ApprienProductListProduct> products;
};

int requestResponseCode;
std::string httpErrorMessage;

void SendError(int code, std::basic_string<char, std::char_traits<char>, std::allocator<char>> basicString);

void from_json(const json &j, ApprienProductList &s) {
    const json &sj = j.at("products");
    s.products.resize(sj.size());
    std::copy(sj.begin(), sj.end(), s.products.begin());
}

std::string ApprienManager::ApprienIdentifier() {
    std::stringstream ss;
    ss << std::hex << SHA256(deviceUniqueIdentifier)[0];
    return ss.str();
}

void ApprienManager::CatchAndSendRequestError() {
    if (requestResponseCode != 0) {
        std::string errorMessage = "Error occured while posting products shown: HTTP error: " + httpErrorMessage;
        SendError(requestResponseCode, errorMessage);
    }
}

void ApprienManager::SendError(int responseCode, std::string errorMessage) {
    char url[5000];
    auto request = WebRequest();
    std::string code = std::to_string(responseCode);
    std::snprintf(url, sizeof(url), REST_POST_ERROR_URL, errorMessage.c_str(), code.c_str(), gamePackageName.c_str(), StoreIdentifier().c_str());
   // request.Get(url, std::function<void(WebRequest)>());
    request.SendWebRequest();
}

bool ApprienManager::CheckServiceStatus(std::function<void(int response, int errorCode)> callback) {
    auto request = WebRequest();
    request.Get(REST_GET_APPRIEN_STATUS, callback);
    request.SendWebRequest();

    if (request.responseCode != 0) {
        SendError(request.responseCode, "Error occured while posting products shown: HTTP error: " + request.errorMessage);
    }
    return request.isDone;
}

void ApprienManager::CheckTokenValidity(std::function<void(int response, int errorCode)> callback) {
    char url[5000];
    auto request = WebRequest();
    snprintf(url, sizeof(url), REST_GET_VALIDATE_TOKEN_URL, StoreIdentifier().c_str(), gamePackageName.c_str());
    
    NSURLSessionDataTask *dataTask = request.Get(url, callback);
    request.SetRequestHeader("Authorization", "Bearer " + token);
    [dataTask resume];
}

std::vector<ApprienManager::ApprienProduct> Products;
int responseCode;
std::string responseErrorMessage;

std::function<void(std::vector<Apprien::ApprienManager::ApprienProduct> apprienProductsC)> OnFetchPrices;



/// <summary>
/// Parse the JSON data and update the variant IAP ids.
/// </summary>
void FetchPrices(char *data) {
    auto productLookup = new std::map<std::string, ApprienManager::ApprienProduct>();
    try {
        json j = json::parse(data);
        ApprienProductList productList = j;
        for (ApprienProductListProduct product : productList.products) {
            for (int i = 0; i < Products.size(); i++) {
                if (product.base == Products[i].baseIAPId) {
                    Products[i].baseIAPId = product.base;
                    Products[i].apprienVariantIAPId = product.variant;
                }
            }
        }
    }
    catch (const std::exception &e) // If the JSON cannot be parsed, products will be using default IAP ids*/
    {
        std::cout << e.what();
    }

    if (OnFetchPrices != nullptr) {
        OnFetchPrices(Products);
    }

    delete (productLookup);
}

WebRequest ApprienManager::FetchApprienPrices(std::vector<ApprienProduct> apprienProducts, std::function<void(std::vector<Apprien::ApprienManager::ApprienProduct> apprienProductsC)> callback) {
    char url[5000];
    OnFetchPrices = callback;
    Products = apprienProducts;
    auto request = WebRequest();
    snprintf(url, sizeof(url), REST_GET_ALL_PRICES_URL, StoreIdentifier().c_str(), gamePackageName.c_str());
    request.Get(url, std::function<void(int reponse, int errorCode)>());
    request.SetRequestHeader("Authorization", "Bearer " + token);
    request.SetRequestHeader("Session-Id", ApprienIdentifier());
    request.SendWebRequest(FetchPrices);

    responseCode = request.responseCode;
    responseErrorMessage = request.errorMessage;
    apprienProducts = Products;

    return request;
}

void ApprienManager::PostReceipt(std::string receiptJson, std::function<void(int response, int errorCode)> callback) {
    auto formData = std::list<FormDataSection>();
    std::list<FormDataSection>::iterator it = formData.begin();
    formData.insert(it, FormDataSection("receipt", receiptJson.c_str()));

    char url[5000];
    auto request = WebRequest();
    snprintf(url, sizeof(url), REST_POST_RECEIPT_URL, StoreIdentifier().c_str(), gamePackageName.c_str());
    request.Post(url, formData, callback);
    request.SetRequestHeader("Authorization", "Bearer " + token);
    request.SendWebRequest();


}

void ApprienManager::ProductsShown(std::vector<ApprienProduct> apprienProducts, std::function<void(int response, int errorCode)> callback) {
    auto formData = std::list<FormDataSection>();
    std::list<FormDataSection>::iterator it = formData.begin();
    for (unsigned int i = 0; i < apprienProducts.size(); i++) {
        std::ostringstream oss;
        oss << "iap_ids[" << i << "]";
        formData.insert(it, FormDataSection(oss.str(), apprienProducts[i].apprienVariantIAPId.c_str()));
    }

    char url[5000];
    auto request = WebRequest();
    snprintf(url, sizeof(url), REST_POST_PRODUCTS_SHOWN_URL, StoreIdentifier().c_str());
    request.Post(url, formData, callback);
    request.SetRequestHeader("Authorization", "Bearer " + token);
    request.SendWebRequest();

    if (request.responseCode != 0) {
        SendError(request.responseCode, "Error occured while posting products shown: HTTP error: " + request.errorMessage);
    }
}

std::string ApprienManager::GetBaseIAPId(std::string storeIAPId) {
    // Default result to (base) storeIapId
    auto result = storeIAPId;

    // First check if this is a variant IAP id or base IAP id
    std::size_t apprienSeparatorPosition = result.find(".apprien_");
    if (apprienSeparatorPosition != std::string::npos) {
        // Get the base IAP id part, remove the suffix
        result = result.substr(0, apprienSeparatorPosition);

        // Remove prefix
        result = result.substr(2);
    }
    return result;
}

std::vector<ApprienManager::ApprienProduct> ApprienManager::ApprienProduct::FromIAPCatalog(std::vector<std::string> catalog) {
    auto apprienProducts = std::vector<ApprienProduct>();
    for (auto &product : catalog) {
        apprienProducts.push_back(ApprienProduct(product));
    }
    return apprienProducts;
}

void ApprienManager::TestConnection(std::function<void(BOOL statusCheck, BOOL tokenCheck)> callback) {
    // Checks service status and validates the token
    CheckServiceStatus(^(int response, int error) {
        if(error == 0 && response == 0){
            CheckTokenValidity(^(int response, int error) {
                CompleteValidateServices(callback, response, error);
            });
        }
        else{
            //Service is down cannot check token
            callback(false, false);
        }
    });
}

void ApprienManager::CompleteValidateServices(const std::function<void(BOOL, BOOL)> &callback, int response, int error) const {
    if(error == 0 && response == 0){
        //Service and token ok
        callback(true, true);
    }
    else{
        //service up, but token is not valid
        callback(true, false);
    }
}
