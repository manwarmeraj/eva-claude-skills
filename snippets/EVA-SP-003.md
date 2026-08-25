```csharp
// WRONG - NullReferenceException the day the proc stops returning TotalCount
int total = (int)sqlParams.FirstOrDefault(x => x.ParameterName == "TotalCount").Value;

// RIGHT - null-safe on the parameter and on its value
int total = (int)((sqlParams.FirstOrDefault(x => x.ParameterName == "TotalCount")?.Value) ?? 0);
```

The guard is cheap and the failure it prevents is a 500 with no useful message. Apply it to every output-parameter read, including ones you are certain the proc sets.
