```csharp
// WRONG - joins ModelStateEntry objects, so the client gets type names, not errors
var message = string.Join("", ModelState.Values);

// ALSO WRONG - the "" separator runs all the messages together
var message = string.Join("", ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));

// RIGHT
var message = string.Join(", ",
    ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage));
```

You will see the `string.Join("")` form in older controllers. It is a real bug,
not a convention — do not copy it into new actions.
