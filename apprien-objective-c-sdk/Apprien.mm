#import <sstream>
#import <iostream>
#import "Apprien.h"
#import "sha256.h"
#import "json.hpp"
using namespace Apprien;

using json = nlohmann::json;

class ApprienProductListProduct {
public:
    std::string base;
    std::string variant;
};


int responseCode;
std::string responseErrorMessage;
std::function<void(std::vector<Apprien::ApprienManager::ApprienProduct> apprienProductsC)> OnFetchPrices;
int requestResponseCode;
std::string httpErrorMessage;

void from_json(const json &j, ApprienProductListProduct &sb) {
    sb.base = j["base"].get<std::string>();
    sb.variant = j["variant"].get<std::string>();
}

/// <summary>
/// Product list class used for parsing JSON.
/// </summary>
class ApprienProductList {
public:
   // std::list<ApprienProductListProduct> products;
};

void SendError(int code, std::basic_string<char, std::char_traits<char>, std::allocator<char>> basicString);

void from_json(const json &j, ApprienProductList &s) {
   // const json &sj = j.at("products");
    //s.products.resize(sj.size());
    //std::copy(sj.begin(), sj.end(), s.products.begin());
}

std::string Apprien::ApprienManager::ApprienIdentifier() {
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
  /*  char url[5000];
    auto request = WebRequest();
    std::string code = std::to_string(responseCode);
    std::snprintf(url, sizeof(url), REST_POST_ERROR_URL, errorMessage.c_str(), code.c_str(), gamePackageName.c_str(), StoreIdentifier().c_str());
   // request.Get(url, std::function<void(WebRequest)>());
    request.SendWebRequest();*/
}


void Apprien::ApprienManager::PostReceipt(std::string receiptJson, std::function<void(int response, int errorCode)> callback) {
    /*
    NSMutableArray<FormDataSection*>*formDataArray = [[NSMutableArray<FormDataSection*> alloc] init];
    FormDataSection *data = [[FormDataSection alloc] init];
    data.Name = @"receipt";
   // data.Data =receiptJson.c_str();
    [formDataArray addObject:data]

    char url[5000];
   // auto request = WebRequest();
    snprintf(url, sizeof(url), REST_POST_RECEIPT_URL, StoreIdentifier().c_str(), gamePackageName.c_str());
    request.Post(url, formData, callback);
    request.SetRequestHeader("Authorization:", "Bearer " + token);
    request.SendWebRequest();*/
}

void Apprien::ApprienManager::ProductsShown(std::vector<ApprienProduct> apprienProducts, std::function<void(int response, int errorCode)> callback) {
    /* auto formData = std::list<FormDataSection>();
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
    request.SetRequestHeader("Authorization:", "Bearer " + token);
    request.SendWebRequest();

    if (request.responseCode != 0) {
        SendError(request.responseCode, "Error occured while posting products shown: HTTP error: " + request.errorMessage);
    }*/
}


std::vector<ApprienManager::ApprienProduct> Apprien::ApprienManager::ApprienProduct::FromIAPCatalog(std::vector<std::string> catalog) {
    auto apprienProducts = std::vector<ApprienProduct>();
    for (auto &product : catalog) {
        apprienProducts.push_back(ApprienProduct(product));
    }
    return apprienProducts;
}
/// <summary>
/// Parse the JSON data and update the variant IAP ids.
/// </summary>
std::vector<ApprienManager::ApprienProduct> Apprien::ApprienManager::GetProducts(char *data) {
    std::vector<ApprienManager::ApprienProduct> products;
    /*auto productLookup = new std::map<std::string, ApprienManager::ApprienProduct>();
    try {
        json j = json::parse(data);
        ApprienProductList productList = j;
        for (ApprienProductListProduct product : productList.products) {
            for (int i = 0; i < products.size(); i++) {
                if (product.base == products[i].baseIAPId) {
                    products[i].baseIAPId = product.base;
                    products[i].apprienVariantIAPId = product.variant;
                }
            }
        }
    }
    catch (const std::exception &e) // If the JSON cannot be parsed, products will be using default IAP ids
    {
        std::cout << e.what();
    }

    delete (productLookup);*/
    return products;
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
