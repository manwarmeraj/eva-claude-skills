```csharp
// WRONG - a failed write returning 200 makes the client treat it as saved
[HttpPost]
public async Task<IActionResult> Add([FromBody] FgModel model)
{
    var response = await _fgBusiness.Add(model);
    return Ok(response);
}

// RIGHT - writes signal failure through the status code
[HttpPost]
public async Task<IActionResult> Add([FromBody] FgModel model)
{
    var response = await _fgBusiness.Add(model);
    if (!response.Success)
        return BadRequest(response);
    return Ok(response);
}

// RIGHT - reads still return 200 with an empty payload
[HttpGet]
public async Task<IActionResult> GetAll()
{
    var response = await _fgBusiness.GetAll();
    return Ok(response);
}
```

Only 200 and 400 are used platform-wide (`EVA-CTL-010`). Do not introduce 404,
422, or 500 from a controller.
