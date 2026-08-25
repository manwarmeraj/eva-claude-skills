The mirror image of [`EVA-RSP-001`](#eva-rsp-001). The envelope belongs to the Business layer and
nowhere else.

```csharp
// WRONG - the Business layer now has to unwrap and rewrap, and response codes
//         have leaked into the data layer
public interface IPriceListRepository
{
    Task<BaseResponse<List<PriceListModel>>> GetAll();
    Task<BaseResponse<bool>> Add(PriceListAddModel model);
}

// RIGHT - raw shapes: entity, DTO, bool, int, List<>
public interface IPriceListRepository
{
    Task<List<PriceListModel>> GetAll();
    Task<PriceListModel> Get(long priceListId);
    Task<bool> Add(PriceListAddModel model);
    Task<bool> Update(PriceListUpdateModel model);
    Task<bool> Delete(List<long> priceListIds);
}
```

The implementation stays plain — no `BaseResponse` local, no `ResponseType`:

```csharp
public async Task<List<PriceListModel>> GetAll()
{
    return await _unitOfWork.DataContext.Set<PriceList>()
        .AsNoTracking()
        .Where(x => x.OrgId == _orgId)                  // tenancy is still the repository's job
        .Select(x => new PriceListModel { /* ... */ })
        .ToListAsync();
}
```

What stays in the repository: `OrgId` filtering, `AsNoTracking`, transactions, proc calls.
What moves out: `BaseResponse<T>`, `ResponseType`, `.Success(...)` / `.Failure(...)`, resx codes.

**It moves up exactly one layer — to Business, not to the controller.** The envelope is built in the
Business method that calls this repository:

```csharp
// Business - wraps the raw result. This is where BaseResponse<T> appears.
public async Task<BaseResponse<List<PriceListModel>>> GetAll()
{
    BaseResponse<List<PriceListModel>> response = new();

    var rows = await _priceListRepository.GetAll() ?? new List<PriceListModel>();

    return response.Success(rows, ResponseType.Common_DataFetchSuccess);
}

// Controller - passes it through, never constructs one
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var response = await _priceListBusiness.GetAll();
    return Ok(response);
}
```

A Business method that returns a raw `List<>` is just as wrong as a repository that returns
`BaseResponse<T>` — see [`EVA-RSP-001`](#eva-rsp-001).

A repository signals "nothing found" with an empty list or `null`, and "write failed" with `false` or
an affected-row count of `0`. The Business layer turns that into a response code.
