```csharp
// WRONG - the failure disappears; the caller sees a success-shaped empty result
try
{
    await _repository.Update(entity);
}
catch (Exception ex)
{
}

// ALSO WRONG - a comment is not handling
catch (Exception ex)
{
    // ignore, not important
}

// RIGHT - log it
catch (Exception ex)
{
    _logger.Error(nameof(FgDesignRepository), nameof(Update), ex.Message, ex.StackTrace);
    return response.Failure(ResponseType.Err_UnhandledException);
}

// RIGHT - or let ErrorHandlingMiddleware deal with it and do not catch at all
```

`catch (Exception ex)` is explicitly allowed in EvA (Sonar S2221 is off). Only
**silence** is banned: log, rethrow, or return a `Failure(...)`.
