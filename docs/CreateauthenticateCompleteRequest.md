# CreateauthenticateCompleteRequest

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**credentialId** | **String** | The globally unique identifier of the public key credentials. | [optional] 
**authenticatorData** | **String** | Information from the authenticator such as the Relying Party ID Hash (&#x60;rpIdHash&#x60;), a signature counter, test of user presence and user verification flags, and any extensions processed by the authenticator. | [optional] 
**clientDataJSON** | **String** | The client data for the authentication, such as origin and challenge. | [optional] 
**signature** | **String** | An assertion signature over &#x60;authenticatorData&#x60; and &#x60;clientDataJSON&#x60; used to verify the authenticity of the request. The assertion signature is created with the private key of keypair that was created during the &#x60;navigator.credentials.create()&#x60; call and verified using the public key of that same keypair. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


