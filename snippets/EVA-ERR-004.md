```csharp
// WRONG - goes stale on rename, and is already wrong here (copied from another class)
_logger.Error("PriceStructure", "Update", ex.Message, ex.StackTrace);

// RIGHT - nameof() follows renames
_logger.Error(nameof(OpportunityQuoteRepository), nameof(Update), ex.Message, ex.StackTrace);
```
