```xml
<!-- WRONG - EVA.PriceList.Business.csproj -->
<PropertyGroup>
  <TargetFramework>net10.0</TargetFramework>
  <ImplicitUsings>enable</ImplicitUsings>
</PropertyGroup>
```

```csharp
// RIGHT - using.cs at the project root: hand-written, reviewable, greppable
global using System.Data;
global using Microsoft.EntityFrameworkCore;
global using EVA.PriceList.Common.ResponseMessages;
global using EVA.PriceList.ViewModel;
```

Every EvA project keeps its global usings in `using.cs`, so a reviewer can see exactly what is in scope without reasoning about SDK defaults. Add your namespace there rather than turning `ImplicitUsings` on.
