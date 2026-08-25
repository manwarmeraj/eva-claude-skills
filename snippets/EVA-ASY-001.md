```csharp
// WRONG - deadlocks under IIS, and hides the real exception inside AggregateException
var result = _repository.GetAll().Result;

// RIGHT
var result = await _repository.GetAll();
```

If awaiting forces you to make the caller async too, make it async. Do not stop
the propagation with `.Result`.
