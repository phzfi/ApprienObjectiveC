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

@implementation WebRequest : NSObject

-(id)init {
     if (self = [super init])  {
         self.isDone = false;
         self.responseCode = -1;
         self.errorMessage = @"";
         self.CURL_CA_BUNDLE = "curl-ca-bundle.crt";
     }
     return self;
}
NSMutableURLRequest *request;
NSURLSession *session;
NSURLSessionDataTask *dataTask;
NSURLSessionUploadTask *uploadTask;

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



-(NSMutableURLRequest *)Initialize: (NSString *)url httpMethod: (NSString*) httpMethod
{
    if(session == nil){
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config];
    }
    
    NSURL *nsurl = [NSURL URLWithString:url];
    request = [[NSMutableURLRequest alloc] initWithURL:nsurl];
    request.HTTPMethod = httpMethod;
    
    return request;
}
 
 -(void) URLSession:(NSURLSession *)session challenge:( NSURLAuthenticationChallenge *)challenge path: (NSString *)path callback: (void (^)(NSURLSessionAuthChallengeDisposition response, NSURLCredential *errorCode)) callback
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
        callback(NSURLSessionAuthChallengeUseCredential, credential);
    }
    else
    {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        callback(NSURLSessionAuthChallengeRejectProtectionSpace, nil);
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

-(bool) SendWebRequest: (void (^)(char *data)) callback
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

-(void) SetRequestHeader:(NSString *)name value: (NSString *)value
{
  
    NSString *headerName = [NSString stringWithCString: name.c_str() encoding:NSString.defaultCStringEncoding];
    NSString *headerValue = [NSString stringWithCString: value.c_str() encoding:NSString.defaultCStringEncoding];
      
    
    [request addValue:headerValue forHTTPHeaderField:headerName];
}

-(NSMutableURLRequest *)Get: (NSString *)url
{
    return [self Initialize: url httpMethod: @"GET"];
}

-(NSURLSessionUploadTask *)Post: (NSString *)url dataFormSections: (NSMutableArray<FormDataSection*>*) formSections callBack: (void (^)(int response, int errorCode)) callBack
{
    [self Initialize:url httpMethod: @"POST"];
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];;
    
    for (FormDataSection *item  in formSections)
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

-(int) HandleResponse:(NSURLResponse *)response error: (NSError *)error {// Handle response here
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

-(NSURLSessionUploadTask *)Post:(NSString *) url postData: (const char *)postData
{
    NSString *str = [NSString stringWithCString: postData encoding:NSString.defaultCStringEncoding ];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];

    uploadTask = [session uploadTaskWithRequest:request
                    fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
        // Handle response here
    }];
    
    
    return uploadTask;
}
@end
