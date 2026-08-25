```csharp
// WRONG - four separate violations in one action
[HttpGet]
public async Task<IActionResult> GetAll()
{
    try                                                   // no try/catch in controllers
    {
        var rows = await _dbContext.FinishedGoods         // no DbContext in controllers
            .Where(x => x.OrgId == orgId).ToListAsync();  // no business logic in controllers
        return Ok(rows);
    }
    catch (Exception ex)
    {
        _logger.Error(...);                               // no ILogger in controllers
        return BadRequest();
    }
}

// RIGHT - bind, guard, delegate, map
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var response = await _finishedGoodsBusiness.GetAll();
    if (!response.Success)
        return BadRequest(response);
    return Ok(response);
}
```

`ErrorHandlingMiddleware` already catches and logs everything a controller could
throw. A try/catch here just hides the failure from it.
