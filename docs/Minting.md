# Minting

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** |  | [optional] [readonly] 
**startedAt** | **Date** | The time at which the transaction was initiated by the connected Ethereum node. | [optional] 
**minedAt** | **Date** | The time at which the transaction first appeared in a mined block. | [optional] 
**blockNumber** | **Int** | The first block in which the transaction was visible. | [optional] 
**blockConfirmations** | **Int** | The number of subsequent blocks (if available) that include the minting transaction. | [optional] 
**transactionHash** | **String** | The transaction hash for the Project&#39;s minting contract. | [optional] 
**destinationWallet** | **String** | The hashed checksum public address of the destination wallet. | [optional] 
**project** | **String** | The Project being minted. | [optional] 
**tokenId** | **Int** | The integer ID of the token that was minted by the PBAB contract. | [optional] 
**metadata** | [**AnyCodable**](.md) | The metadata for the token retrieved from the Art Blocks API. | [optional] 
**embedUrl** | **String** | The full URL of the embeddable live view of the minted art. | [optional] 
**receipt** | [**MintingReceipt**](MintingReceipt.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


