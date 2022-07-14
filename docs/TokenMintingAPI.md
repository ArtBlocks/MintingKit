# TokenMintingAPI

All URIs are relative to *https://minting-api.artblocks.io*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createMinting**](TokenMintingAPI.md#createminting) | **POST** /minting | Mint new token
[**listMintings**](TokenMintingAPI.md#listmintings) | **GET** /minting | List token receipts
[**retrieveMinting**](TokenMintingAPI.md#retrieveminting) | **GET** /minting/{id} | Retrieve token receipt


# **createMinting**
```swift
    open class func createMinting(createMintingRequest: CreateMintingRequest? = nil, completion: @escaping (_ data: Minting?, _ error: Error?) -> Void)
```

Mint new token

This endpoint initiates a new request to mint an NFT using a Powered by Art Blocks project.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let createMintingRequest = createMinting_request(destinationWallet: "destinationWallet_example", project: "project_example") // CreateMintingRequest |  (optional)

// Mint new token
TokenMintingAPI.createMinting(createMintingRequest: createMintingRequest) { (response, error) in
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
 **createMintingRequest** | [**CreateMintingRequest**](CreateMintingRequest.md) |  | [optional] 

### Return type

[**Minting**](Minting.md)

### Authorization

[BasicAuth](../README.md#BasicAuth), [BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listMintings**
```swift
    open class func listMintings(page: Int? = nil, completion: @escaping (_ data: ListMintings200Response?, _ error: Error?) -> Void)
```

List token receipts

List all of the previous requests to mint a token initiated by this machine.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let page = 987 // Int | A page number within the paginated result set. (optional)

// List token receipts
TokenMintingAPI.listMintings(page: page) { (response, error) in
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

[**ListMintings200Response**](ListMintings200Response.md)

### Authorization

[BasicAuth](../README.md#BasicAuth), [BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **retrieveMinting**
```swift
    open class func retrieveMinting(id: String, completion: @escaping (_ data: Minting?, _ error: Error?) -> Void)
```

Retrieve token receipt

Retrieve the details of a specific minted token.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let id = "id_example" // String | A primary key string identifying this minting.

// Retrieve token receipt
TokenMintingAPI.retrieveMinting(id: id) { (response, error) in
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
 **id** | **String** | A primary key string identifying this minting. | 

### Return type

[**Minting**](Minting.md)

### Authorization

[BasicAuth](../README.md#BasicAuth), [BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

