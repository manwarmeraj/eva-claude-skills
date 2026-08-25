```csharp
// WRONG in eva-crm-api - the gateway strips the first segment and routes on the module
[Route("api/[controller]/[action]")]

// RIGHT - module prefix matches the repo
[Route("api/crm/[controller]/[action]")]
```

Look your repo's prefix up in the registry table in
[architecture.md](architecture.md) — do not guess it from the folder name.
`eva-api` is the one repo whose prefix is plain `api`.
