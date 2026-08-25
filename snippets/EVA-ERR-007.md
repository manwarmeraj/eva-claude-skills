```csharp
// WRONG - blocks the thread, and no retry on a transient SQL failure
_uow.DataContext.SaveChanges();

// RIGHT - execution strategy + explicit transaction
var strategy = _uow.DataContext.Database.CreateExecutionStrategy();
await strategy.ExecuteAsync(async () =>
{
    using var transaction = await _uow.DataContext.Database.BeginTransactionAsync();

    _uow.DataContext.Set<DesignOverrideReason>().Add(entity);
    await _uow.DataContext.SaveChangesAsync();

    await transaction.CommitAsync();
});
```

Related: `AsNoTracking()` on every read, and `ExecuteDeleteAsync()` for bulk
deletes instead of loading entities to remove them.
