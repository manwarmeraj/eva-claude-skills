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

A repository signals "nothing found" with an empty list or `null`, and "write failed" with `false` or
an affected-row count of `0`. The Business layer turns that into a response code.
