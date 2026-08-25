```csharp
// WRONG - runs against the tenant DB, but returns every org's rows in it
var rows = await _uow.DataContext.Set<DesignOverrideReason>()
    .AsNoTracking()
    .Where(x => x.IsActive)
    .ToListAsync();

// RIGHT - _orgId comes from HttpContext.Items[KeyConstant.AppOrgId]
var rows = await _uow.DataContext.Set<DesignOverrideReason>()
    .AsNoTracking()
    .Where(x => x.IsActive && x.OrgId == _orgId)
    .ToListAsync();
```

Connecting to the right tenant database is **not** a substitute for the `OrgId`
filter. One database holds many orgs. Both are required.
