#include <list>
#include <iostream>
#include <functional>
#include <sstream>
#import "FormDataSection.h"
#import <Foundation/Foundation.h>



/// <summary>
/// The WebRequest class is used to communicate with web servers.
/// </summary>
class WebRequest
{
private:

    struct curl_slist *chunk = NULL;

    bool Initialize(std::string url, NSString* httpMethod);

public:
    /// <summary>
    /// Value is true after the WebRequest has finished communicating with the remote.
    /// </summary>
    bool isDone = false;

    /// <summary>
    /// The numeric error code returned by the WebRequest.
    /// </summary>
    int responseCode = -1;

    /// <summary>
    /// Human readable error string that may offer more details about the cause of the error code.
    /// </summary>
    std::string errorMessage = "";

    
    /// <summary>
    /// Certificate Authority bundle file.
    /// </summary>
    const char *CURL_CA_BUNDLE = "curl-ca-bundle.crt";

    /// <summary>
    /// Begin communicating with the remote server.
    /// </summary>
    bool SendWebRequest(std::function<void(char *)> callback = nullptr);

    /// <summary>
    /// Set a custom value to HTTP request header.
    /// </summary>
    void SetRequestHeader(std::string name, std::string  value);

    /// <summary>
    /// Create a WebRequest for HTTP GET.
    /// </summary>
    NSURLSessionDataTask *Get(std::string url, std::function<void(int response, int error)> callBack);

    /// <summary>
    /// Create a WebRequest configured to send form data to a server via HTTP POST.
    /// </summary>
    NSURLSessionUploadTask *Post(std::string url, std::list<FormDataSection> formSections, std::function<void(int response, int errorCode)> callBack);

    /// <summary>
    /// Create a WebRequest configured to send post data to a server via HTTP POST.
    /// </summary>
    NSURLSessionUploadTask *Post(std::string url, const char *postData = nullptr);

    int HandleResponse(NSURLResponse *response, NSError *error) const;
};

