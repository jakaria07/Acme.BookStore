# Build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy solution file
COPY Acme.BookStore.sln ./

# Copy project files (preserving directory structure)
COPY src/Acme.BookStore.Application.Contracts/*.csproj ./src/Acme.BookStore.Application.Contracts/
COPY src/Acme.BookStore.Application/*.csproj ./src/Acme.BookStore.Application/
COPY src/Acme.BookStore.DbMigrator/*.csproj ./src/Acme.BookStore.DbMigrator/
COPY src/Acme.BookStore.Domain.Shared/*.csproj ./src/Acme.BookStore.Domain.Shared/
COPY src/Acme.BookStore.Domain/*.csproj ./src/Acme.BookStore.Domain/
COPY src/Acme.BookStore.EntityFrameworkCore/*.csproj ./src/Acme.BookStore.EntityFrameworkCore/
COPY src/Acme.BookStore.HttpApi.Client/*.csproj ./src/Acme.BookStore.HttpApi.Client/
COPY src/Acme.BookStore.HttpApi.Host/*.csproj ./src/Acme.BookStore.HttpApi.Host/
COPY src/Acme.BookStore.HttpApi/*.csproj ./src/Acme.BookStore.HttpApi/

# Copy test project files
COPY test/Acme.BookStore.Application.Tests/*.csproj ./test/Acme.BookStore.Application.Tests/
COPY test/Acme.BookStore.Domain.Tests/*.csproj ./test/Acme.BookStore.Domain.Tests/
COPY test/Acme.BookStore.EntityFrameworkCore.Tests/*.csproj ./test/Acme.BookStore.EntityFrameworkCore.Tests/
COPY test/Acme.BookStore.HttpApi.Client.ConsoleTestApp/*.csproj ./test/Acme.BookStore.HttpApi.Client.ConsoleTestApp/
COPY test/Acme.BookStore.TestBase/*.csproj ./test/Acme.BookStore.TestBase/

# Add NuGet config for reliability
COPY nuget.config ./

# Restore with retry, longer timeout, and fallback config
RUN dotnet restore Acme.BookStore.sln \
    --configfile nuget.config \
    /p:RestoreRetries=5 \
    /p:RestoreTimeout=300 \
    --verbosity normal

# Copy all source code
COPY . .

# Publish the host project
WORKDIR /src/src/Acme.BookStore.HttpApi.Host
RUN dotnet publish -c Release -o /app --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0
WORKDIR /app
COPY --from=build /app ./

COPY src/Acme.BookStore.HttpApi.Host/openiddict.pfx ./

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["dotnet", "Acme.BookStore.HttpApi.Host.dll"]