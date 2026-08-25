```csharp
// WRONG - DataAnnotations on the model are never checked
[HttpPost]
public async Task<IActionResult> Add([FromBody] DesignOverrideReasonInputModel inputModel)
{
    var response = await _designOverrideReasonBusiness.Add(inputModel);
    ...
}

// RIGHT
[HttpPost]
public async Task<IActionResult> Add([FromBody] DesignOverrideReasonInputModel inputModel)
{
    if (!ModelState.IsValid)
    {
        var message = string.Join(", ",
            ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
        return BadRequest(message);
    }

    var response = await _designOverrideReasonBusiness.Add(inputModel);
    if (!response.Success)
        return BadRequest(response);

    return Ok(response);
}
```

DataAnnotations is the **only** validation layer in EvA — there is no
FluentValidation anywhere. Skip the guard and invalid payloads reach the database.
