```csharp
// WRONG - .NET-default names that no EvA client contract uses
public class PriceListDto { }
public class CreatePriceListRequest { }
public class PriceListResponse { }
public class PriceListViewModel { }

// RIGHT - the EvA suffix set
public class PriceListModel { }        // general shape
public class PriceListAddModel { }     // create payload
public class PriceListUpdateModel { }  // update payload
public class PriceListReadModel { }    // single read
public class PriceListGetAllModel { }  // list read
public class PriceListResultModel { }  // proc / query projection
```

The full allowed set: `Model`, `ToCreateModel`, `ToUpdateModel`, `AddModel`, `UpdateModel`, `ReadModel`, `GetAllModel`, `ResultModel`. They live in `EVA.<Domain>.ViewModel(s)`.

Note the project is named `ViewModel` but no class is ever suffixed `ViewModel`.
