
#import "FormDataSection.h"
#import <Foundation/Foundation.h>

/// <summary>
/// The WebRequest class is used to communicate with web servers.
/// </summary>
@interface WebRequest : NSObject

    /// <summary>
    /// Value is true after the WebRequest has finished communicating with the remote.
    /// </summary>
    @property(nonatomic) bool isDone;

    /// <summary>
    /// The numeric error code returned by the WebRequest.
    /// </summary>
    @property(nonatomic) int responseCode;

    /// <summary>
    /// Human readable error string that may offer more details about the cause of the error code.
    /// </summary>
    @property(nonatomic) NSString *errorMessage;

    /// <summary>
    /// Certificate Authority bundle file.
    /// </summary>
    @property(nonatomic) NSString *CURL_CA_BUNDLE;

    /// <summary>
    /// Get session.
    /// </summary>
    @property(nonatomic) NSURLSession *GetSession;

    -(NSMutableURLRequest *)Initialize: (NSString *)url httpMethod: (NSString*) httpMethod;

    /// <summary>
    /// Begin communicating with the remote server.
    /// </summary>
    -(bool) SendWebRequest: (void (^)(char *data)) callback;

    /// <summary>
    /// Set a custom value to HTTP request header.
    /// </summary>
    -(void) SetRequestHeader:(NSString *)name value: (NSString *)value;

    /// <summary>
    /// Create a WebRequest for HTTP GET.
    /// </summary>
    -(NSMutableURLRequest *)Get: (NSString *)url;

    /// <summary>
    /// Create a WebRequest configured to send form data to a server via HTTP POST.
    /// </summary>
    -(NSURLSessionUploadTask *)Post: (NSString *)url dataFormSections: (NSMutableArray<FormDataSection*>*) formSections callBack: (void (^)(int response, int errorCode)) callBack;

    /// <summary>
    /// Create a WebRequest configured to send post data to a server via HTTP POST.
    /// </summary>
    -(NSURLSessionUploadTask *)Post:(NSString *) url postData: (const char *)postData;

    -(int) HandleResponse:(NSURLResponse *)response error: (NSError *)error;
@end

