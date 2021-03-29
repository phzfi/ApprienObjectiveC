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
    
    if(session == nil){
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:config];
    }
    
    NSURL *nsurl = [NSURL URLWithString:[NSString stringWithCString:url.c_str() encoding:NSString.defaultCStringEncoding]];
    request = [[NSMutableURLRequest alloc] initWithURL:nsurl];
    request.HTTPMethod = httpMethod;
    
    return true;
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

bool WebRequest::Get(std::string url)
{
    Initialize(url, @"GET");
    
    dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response; //must do type cast to get accss to statusCode etc
        int responseCode = (int)httpResponse.statusCode;
        NSString *errorMessage = [NSString stringWithFormat: @"%ld", (long)error.code];
        if (responseCode != 0) {
         //   SendError(request.responseCode, "Error occured while checking token validity: HTTP error: " + request.errorMessage);
            NSLog(@"Response code is: %d", responseCode);
            NSLog(@"Error message is:  %@", errorMessage);
        }
    }];

    return true;
}

bool WebRequest::Post(std::string url, std::list<FormDataSection> formSections)
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];;
    
    for (auto item : formSections)
    {
        [dictionary setObject:[NSString stringWithCString: item.Data encoding:NSString.defaultCStringEncoding ] forKey:[NSString stringWithCString: item.Name.c_str() encoding:NSString.defaultCStringEncoding ] ];
    }
    // 3
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                    options:kNilOptions error:&error];
    
    if (!error) {
        // 4
        uploadTask = [session uploadTaskWithRequest:request fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            // Handle response here
        }];
        
        return false;
    }
    return true;
}

bool WebRequest::Post(std::string url, const char *postData)
{
    NSString *str = [NSString stringWithCString: postData encoding:NSString.defaultCStringEncoding ];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error = nil;
    
    if (!error) {
        // 4
        uploadTask = [session uploadTaskWithRequest:request
                        fromData:data completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            // Handle response here
        }];
        
        return false;
    }
    return true;
}
