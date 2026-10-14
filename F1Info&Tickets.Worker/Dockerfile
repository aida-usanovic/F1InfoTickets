# The Model project uses ASP.NET Core types (IFormFile, JWT), so the worker needs the ASP.NET runtime.
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["F1Info&Tickets.Model/F1Info&Tickets.Model.csproj", "F1Info&Tickets.Model/"]
COPY ["F1Info&Tickets.Worker/F1Info&Tickets.Worker.csproj", "F1Info&Tickets.Worker/"]
RUN dotnet restore "./F1Info&Tickets.Worker/F1Info&Tickets.Worker.csproj"
COPY . .
WORKDIR "/src/F1Info&Tickets.Worker"
RUN dotnet publish "./F1Info&Tickets.Worker.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "F1Info&Tickets.Worker.dll"]
