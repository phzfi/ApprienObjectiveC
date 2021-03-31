#include "WebRequest.h"
#include <fstream>

#include <stdio.h>
#ifdef _WIN32
#include <direct.h>
#define GetCurrentDir _getcwd
#else
#include <unistd.h>
#define GetCurrentDir getcwd
#endif

inline char Separator()
{
#ifdef _WIN32
    return '\\';
#else
    return '/';
#endif
}

std::string WorkingDir()
{
    char buff[FILENAME_MAX];
    GetCurrentDir(buff, FILENAME_MAX);
    return std::string(buff);
}

inline bool FileExists(const std::string &name)
{
    std::ifstream f(name.c_str());
    return f.good();
}

int WebRequest::CURL_VERBOSE = 0;
int WebRequest::CURL_NOPROGRESS = 1;
int WebRequest::CURL_VERIFYPEER = 1;
NSMutableURLRequest *request;
NSURLSession *session;
NSURLSessionDataTask *dataTask;
NSURLSessionUploadTask *uploadTask;

bool WebRequest::Initialize(std::string url, NSString* httpMethod)
{
    auto certFile = WorkingDir() + Separator() + CURL_CA_BUNDLE;
    if(session == nil){
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config];
    }
    
    NSURL *nsurl = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:NSString.defaultCStringEncoding]];
    request = [[NSMutableURLRequest alloc] initWithURL:nsurl];
    request.HTTPMethod = httpMethod;
    
    return true;
}

/*
  1. Adhere to the NSURLSessionDelegate delegate
  2. Initialize NSURLSession and specify self as delegate (e.g. [NSURLSession sessionWithConfiguration:defaultConfigObject delegate:self delegateQueue: [NSOperationQueue mainQueue]];)
  3. Add the method below to your class
  4. Change the certificate resource name
*/
 
 void URLSession(NSURLSession * session, NSURLAuthenticationChallenge *challenge, NSString *path, std::function<void(NSURLSessionAuthChallengeDisposition, NSURLCredential *)> completionHandler )
{
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
    NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));

    NSString *cerPath = path;
    NSData *localCertData = [NSData dataWithContentsOfFile:cerPath];
    
    if ([remoteCertificateData isEqualToData:localCertData])
    {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
    }
}

std::function<void(char *)> OnWebRequest;

size_t RequestCallback(char *buffer, size_t size, size_t nitems, void *data)
{
    if (OnWebRequest != nullptr)
    {
        OnWebRequest(buffer);
    }
    return size * nitems;
}

bool WebRequest::SendWebRequest(std::function<void(char *)> callback)
{
    if(dataTask){
        [dataTask resume]; //send the HTTP request
        OnWebRequest = callback;
        return true;
    }
    if(uploadTask){

        [uploadTask resume];//send the HTTP request
        OnWebRequest = callback;
        return true;
    }

    //If there was no task to send then return
    return false;
}

void WebRequest::SetRequestHeader(std::string name, std::string  value)
{
  
    NSString *headerName = [NSString stringWithCString: name.c_str() encoding:NSString.defaultCStringEncoding];
    NSString *headerValue = [NSString stringWithCString: value.c_str() encoding:NSString.defaultCStringEncoding];
      
    
    [request addValue:headerValue forHTTPHeaderField:headerName];
}

NSURLSessionDataTask *WebRequest::Get(std::string url, std::function<void(int response, int errorCode)> callBack)
{
    Initialize(url, @"GET");
    
    dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        int responseCode = HandleResponse(response, error);
        callBack(responseCode, (int)error.code);
    }];
  
    return dataTask;
}

NSURLSessionUploadTask *WebRequest::Post(std::string url, std::list<FormDataSection> formSections, std::function<void(int response, int errorCode)> callBack)
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];;
    
    for (auto item : formSections)
    {
        [dictionary setObject:[NSString stringWithCString: item.Data encoding:NSString.defaultCStringEncoding ] forKey:[NSString stringWithCString: item.Name.c_str() encoding:NSString.defaultCStringEncoding ] ];
    }
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                    options:kNilOptions error:&error];
    
    if (!error) {
        uploadTask = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            int responseCode = HandleResponse(response, error);
            callBack(responseCode, (int)error.code);
        }];
    }
    return uploadTask;
}

int WebRequest::HandleResponse(NSURLResponse *response, NSError *error) const {// Handle response here
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response; //must do type cast to get accss to statusCode etc
    int responseCode = (int)httpResponse.statusCode;
    NSString *errorMessage = [NSString stringWithFormat: @"%ld", (long)error.code];
    if (responseCode != 0) {
        //SendError(request.responseCode, "Error occurred while checking token validity: HTTP error: " + request.errorMessage);
        NSLog(@"Response code is: %d", responseCode);
        NSLog(@"Error message is:  %@", errorMessage);
    }
    return responseCode;
}

NSURLSessionUploadTask *WebRequest::Post(std::string url, const char *postData)
{
    NSString *str = [NSString stringWithCString: postData encoding:NSString.defaultCStringEncoding ];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];

    uploadTask = [session uploadTaskWithRequest:request
                    fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
        // Handle response here
    }];
    
    
    return uploadTask;
}
