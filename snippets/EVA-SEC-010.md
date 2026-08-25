```
# WRONG - never run these in an EvA API repo
dotnet ef migrations add AddDesignOverrideReason
dotnet ef database update
```

Schema is owned by the DBA team and lives in `eva-tenant-sql` / `eva-database-sql`.
The API's `DbContext` is scaffolded DB-first and hand-maintained to match. Every
`Migrations/` folder in the estate is empty on purpose.

Adding a column means: change the SQL repo, get it deployed, **then** add the
property to the entity here. See [data-access.md](data-access.md).
