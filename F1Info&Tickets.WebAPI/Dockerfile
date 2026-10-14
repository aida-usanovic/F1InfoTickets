FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["F1Info&Tickets.Model/F1Info&Tickets.Model.csproj", "F1Info&Tickets.Model/"]
COPY ["F1Info&Tickets.Services/F1Info&Tickets.Services.csproj", "F1Info&Tickets.Services/"]
COPY ["F1Info&Tickets.WebAPI/F1Info&Tickets.WebAPI.csproj", "F1Info&Tickets.WebAPI/"]
RUN dotnet restore "./F1Info&Tickets.WebAPI/F1Info&Tickets.WebAPI.csproj"
COPY . .
WORKDIR "/src/F1Info&Tickets.WebAPI"
RUN dotnet publish "./F1Info&Tickets.WebAPI.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "F1Info&Tickets.WebAPI.dll"]
