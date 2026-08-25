```csharp
// WRONG - cannot be localised, and drifts from the resx
return response.Failure("Finished good could not be saved");

// RIGHT - add a ResponseType member + a ResponseMessages.resx entry, then reference it
return response.Failure(ResponseType.Err_DataSaveFailed);
```

The enum member name **is** the resx key; `ResponseType.GetDescription()` resolves
it at serialisation time. Adding a message means adding both, in the same PR.
