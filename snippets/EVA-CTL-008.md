```csharp
// WRONG - the Angular client sends neither query strings nor route values
public async Task<IActionResult> Get([FromQuery] Guid designOverrideReasonsId)
public async Task<IActionResult> Get([FromRoute] Guid designOverrideReasonsId)

// RIGHT - scalars in headers, payloads in the body
public async Task<IActionResult> Get([FromHeader] Guid designOverrideReasonsId)
public async Task<IActionResult> Add([FromBody] DesignOverrideReasonInputModel inputModel)

// RIGHT - list/search endpoints POST a SearchParams body
[HttpPost]
public async Task<IActionResult> GetList([FromBody] SearchParams searchParams)
```
