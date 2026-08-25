"No records found" is a **normal outcome of a successful read**, not an error.

```csharp
// WRONG - an empty grid now looks like a broken call to the Angular client
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll();

    if (rows == null || rows.Count == 0)
        return response.Failure(ResponseType.Err_NoRecordFound);   // no

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}

// RIGHT - empty is still success
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll() ?? new List<PriceListModel>();

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}
```

Single-item reads behave the same way — return the default payload, still with success:

```csharp
public async Task<BaseResponse<PriceListModel>> Get(long priceListId)
{
    BaseResponse<PriceListModel> response = new();

    var row = await _priceListRepository.Get(priceListId);         // may be null

    return response.Success(row, ResponseType.Common_DataFetchSuccess);
}
```

**Reads:** `Get`, `GetAll`, `GetList`, `GetById` — always `.Success(...)`.
**Writes:** `Add`, `Update`, `Delete` — may `.Failure(...)`.

This is why the controller returns `Ok(response)` for a read regardless, and `BadRequest(response)`
only for a failed write — [`EVA-CTL-006`](#eva-ctl-006). The two rules are the same contract seen
from two layers.

The `_orgId <= 0` guard is the one exception: no tenant context means the request was never valid, so
a read may still return `.Failure(ResponseType.Err_UnauthorizedAccess)`.
