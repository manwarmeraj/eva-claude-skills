```csharp
// WRONG - ActionResult<T> is not used anywhere in EvA (663 actions, zero uses)
public async Task<ActionResult<DesignOverrideReasonModel>> Get([FromHeader] Guid id)

// WRONG - not async
public IActionResult Get([FromHeader] Guid id)

// RIGHT
public async Task<IActionResult> Get([FromHeader] Guid designOverrideReasonsId)
```
