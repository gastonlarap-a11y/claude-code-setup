# Learning path: C#/.NET + SQL Server + Azure (official, free)

Order matters — each stage produces something runnable before the next. All local
(OrbStack containers), enterprise-shaped from day one.

1. **C# fundamentals** — [learn.microsoft.com/dotnet/csharp](https://learn.microsoft.com/en-us/dotnet/csharp/) +
   the free interactive "C# for Beginners" path. Coming from TypeScript/Kotlin/Go you
   already know 80%: focus on records, pattern matching, LINQ, async/await semantics,
   nullable reference types.
2. **ASP.NET Core minimal API** — [learn.microsoft.com/aspnet/core](https://learn.microsoft.com/en-us/aspnet/core/):
   build a CRUD API with the `architecture` skill's conventions (vertical slices,
   ProblemDetails, options pattern). Compare mentally with NestJS — DI and middleware
   will feel familiar.
3. **EF Core + SQL Server** — [learn.microsoft.com/ef/core](https://learn.microsoft.com/en-us/ef/core/):
   SQL Server 2025 container up (`data-sqlserver` reference), migrations, then the query
   discipline bullets. Also learn raw T-SQL basics — enterprise .NET jobs assume you can
   read an execution plan.
4. **Testing** — xUnit v3 + WebApplicationFactory + Testcontainers on the API you built
   (`testing` skill). This is where the stack's enterprise reputation lives.
5. **Aspire** — re-wire your local setup through an AppHost (`aspire` reference) once
   you have API + DB (+ cache).
6. **Azure** — [learn.microsoft.com/training/azure](https://learn.microsoft.com/en-us/training/azure/):
   deploy the same app to Container Apps + Azure SQL with GitHub Actions OIDC
   (`azure` skill). AZ-204 is the certification track that matches this path if you
   want the credential.

Ask anything against these skills as you go; for API surfaces not covered here, the
agent researches official docs automatically (`/research`).
