#import "WebRequest.h"
#import <fstream>

#import <stdio.h>
#ifdef _WIN32
#import <direct.h>
#define GetCurrentDir _getcwd
#else
#import <unistd.h>
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

NSMutableURLRequest *request;
NSURLSession *session;
NSURLSessionDataTask *dataTask;
NSURLSessionUploadTask *uploadTask;

NSMutableURLRequest *WebRequest::Initialize(std::string url, NSString* httpMethod)
{
    if(session == nil){
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config];
    }
    
    NSURL *nsurl = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:NSString.defaultCStringEncoding]];
    request = [[NSMutableURLRequest alloc] initWithURL:nsurl];
    request.HTTPMethod = httpMethod;
    
    return request;
}
 
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
        OnWebRequest = callback;
        [dataTask resume]; //send the HTTP request

        return true;
    }
    if(uploadTask){
        OnWebRequest = callback;
        [uploadTask resume];//send the HTTP request
 
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

NSMutableURLRequest *WebRequest::Get(std::string url)
{
    return Initialize(url, @"GET");
}

NSURLSession *WebRequest::GetSession(){
    return session;
}

NSURLSessionUploadTask *WebRequest::Post(std::string url, NSMutableArray<FormDataSection*>* formSections, std::function<void(int response, int errorCode)> callBack)
{
    Initialize(url, @"POST");
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];;
    
    for (FormDataSection *item : formSections)
    {
        NSString *name = item.Name;
        [dictionary setObject:[NSString stringWithCString: item.Data encoding:NSString.defaultCStringEncoding ] forKey: name];
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
    if (responseCode != 0 || error.code != 0) {
        //SendError(responseCode, "Error occurred while checking token validity: HTTP error: " + error.code);
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
