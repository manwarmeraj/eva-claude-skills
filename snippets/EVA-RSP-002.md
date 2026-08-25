```csharp
// WRONG - Code and Success drift apart the moment someone edits one of them
return new BaseResponse<bool> { Success = true, Data = result, Code = 1000 };

// WRONG - same problem, assigned instead of constructed
response.Success = true;
response.Data = result;

// RIGHT - the fluent extensions set Code/Success/Data consistently
public async Task<BaseResponse<bool>> Add(DesignOverrideReasonInputModel inputModel)
{
    BaseResponse<bool> response = new();

    if (_orgId <= 0)
        return response.Failure(ResponseType.Err_UnauthorizedAccess);

    var result = await _designOverrideReasonRepository.Add(inputModel);
    if (!result)
        return response.Failure(ResponseType.Err_DataSaveFailed);

    return response.Success(result, ResponseType.Common_DataSaveMsg);
}
```
