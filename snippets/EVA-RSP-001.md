```csharp
// WRONG - the controller cannot tell success from failure, and has no code to return
public Task<List<PriceListModel>> GetAll();
public Task<bool> Add(PriceListAddModel model);

// RIGHT - Business layer speaks BaseResponse<T>
public Task<BaseResponse<List<PriceListModel>>> GetAll();
public Task<BaseResponse<bool>> Add(PriceListAddModel model);
```

Applies to the contract (`I*Business`) as well as the implementation. Private helpers may return
whatever is convenient.

**The Business layer is the only place the envelope is built.** The Repository underneath returns the
raw shape — see [`EVA-RSP-007`](#eva-rsp-007) — so a Business method is where a raw `List<>` or
`bool` becomes a `BaseResponse<T>`:

```csharp
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll();     // raw List<PriceListModel>

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}
```
