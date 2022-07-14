# PBABProjectsAPI

All URIs are relative to *https://minting-api.artblocks.io*

Method | HTTP request | Description
------------- | ------------- | -------------
[**listProjects**](PBABProjectsAPI.md#listprojects) | **GET** /project | List machine projects
[**mintableProject**](PBABProjectsAPI.md#mintableproject) | **GET** /project/{id}/mintable | Check if mintable
[**retrieveProject**](PBABProjectsAPI.md#retrieveproject) | **GET** /project/{id} | Retrieve project


# **listProjects**
```swift
    open class func listProjects(page: Int? = nil, completion: @escaping (_ data: ListProjects200Response?, _ error: Error?) -> Void)
```

List machine projects

API endpoint that allows a machine to retrieve the PBAB projects that it can mint.  This REST endpoint can be used to retrieve the projects and project metadata of existing Powered by Art Blocks contracts. This endpoint only returns the projects for which the current user has permission to mint.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let page = 987 // Int | A page number within the paginated result set. (optional)

// List machine projects
PBABProjectsAPI.listProjects(page: page) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **Int** | A page number within the paginated result set. | [optional] 

### Return type

[**ListProjects200Response**](ListProjects200Response.md)

### Authorization

[BasicAuth](../README.md#BasicAuth), [BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mintableProject**
```swift
    open class func mintableProject(id: String, completion: @escaping (_ data: MintableProject200Response?, _ error: Error?) -> Void)
```

Check if mintable

Look up if a project is currently mintable. This endpoint:  1. Ensures the currently authenticated machine user is within their set quota for the project minting limit if a minting limit was set 2. Checks that the project is within its maximum total invocations specified on as an attribute of the smart contract 3. Verifies the artist wallet is linked with a sufficient balance to mint a new token  In order to avoid preventable user-facing errors that will cause minting to fail, clients should check the state of projects before requesting a new mint. 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | A unique primary key string identifying this project.

// Check if mintable
PBABProjectsAPI.mintableProject(id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String** | A unique primary key string identifying this project. | 

### Return type

[**MintableProject200Response**](MintableProject200Response.md)

### Authorization

[BasicAuth](../README.md#BasicAuth), [BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **retrieveProject**
```swift
    open class func retrieveProject(id: String, completion: @escaping (_ data: Project?, _ error: Error?) -> Void)
```

Retrieve project

API endpoint that allows Project to be created, retrieved, or deleted.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | A unique primary key string identifying this project.

// Retrieve project
PBABProjectsAPI.retrieveProject(id: id) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String** | A unique primary key string identifying this project. | 

### Return type

[**Project**](Project.md)

### Authorization

[BasicAuth](../README.md#BasicAuth), [BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

