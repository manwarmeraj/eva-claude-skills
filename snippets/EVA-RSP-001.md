```csharp
// WRONG - the controller cannot tell success from failure, and has no code to return
public async Task<List<DesignOverrideReasonModel>> GetAll();
public async Task<bool> Add(DesignOverrideReasonInputModel model);

// RIGHT
public async Task<BaseResponse<List<DesignOverrideReasonModel>>> GetAll();
public async Task<BaseResponse<bool>> Add(DesignOverrideReasonInputModel model);
```

This applies to the contract (`I*Business` / `I*Repository`) as well as the
implementation. Internal private helpers may return whatever is convenient.
