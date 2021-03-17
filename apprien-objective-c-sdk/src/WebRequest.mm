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

bool WebRequest::Initialize()
{
    curl = curl_easy_init();
    if (curl)
    {
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, CURL_VERIFYPEER);
        auto certFile = WorkingDir() + Separator() + CURL_CA_BUNDLE;
        if (FileExists(certFile))
        {
            // Path to Certificate Authority bundle
            curl_easy_setopt(curl, CURLOPT_CAINFO, certFile.c_str());
        }
        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, CURL_NOPROGRESS);
        curl_easy_setopt(curl, CURLOPT_VERBOSE, CURL_VERBOSE);
        return true;
    }
    return false;
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
    isDone = false;
    OnWebRequest = callback;
    if (curl)
    {
        if (chunk != NULL)
        {
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, chunk);
        }
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, RequestCallback);
        // Perform the request
        CURLcode curlcode = curl_easy_perform(curl);
        responseCode = curlcode;
        errorMessage = curl_easy_strerror(curlcode);
        // End a libcurl session
        curl_easy_cleanup(curl);
        if (chunk != NULL)
        {
            // Free the custom headers
            curl_slist_free_all(chunk);
        }
        isDone = true;
    }
    return isDone;
}

void WebRequest::SetRequestHeader(std::string name, std::string value)
{
    std::string header = name;
    if (!value.empty())
    {
        header += ": " + value;
    }
    chunk = curl_slist_append(chunk, header.c_str());
}

bool WebRequest::Get(std::string url)
{
    if (Initialize())
    {
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        return true;
    }
    return false;
}

bool WebRequest::Post(std::string url, std::list<FormDataSection> formSections)
{
    if (Initialize())
    {
        std::ostringstream oss;
        for (auto item : formSections)
        {
            oss << item.Name.c_str();
            char *encoded = curl_easy_escape(curl, item.Data, sizeof(item.Data));
            if (encoded)
            {
                oss << encoded;
                curl_free(encoded);
            }
        }
        auto postdata = oss.str();
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postdata.c_str());
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        return true;
    }
    return false;
}

bool WebRequest::Post(std::string url, const char *postData)
{
    if (Initialize())
    {
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, postData);
        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        return true;
    }
    return false;
}
