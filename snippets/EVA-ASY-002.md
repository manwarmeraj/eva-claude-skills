```csharp
// WRONG - all three block a thread pool thread
_repository.Update(entity).Wait();
var x = _repository.Get(id).GetAwaiter().GetResult();
var rows = await Task.Run(() => connection.Query<FgModel>(sql).ToList());

// RIGHT
await _repository.Update(entity);
var x = await _repository.Get(id);
var rows = (await connection.QueryAsync<FgModel>(sql, new { OrgId = _orgId })).ToList();
```

`Task.Run` around a database call does not make it async — it just moves the
blocking to a different thread. Use the real `*Async` API.
