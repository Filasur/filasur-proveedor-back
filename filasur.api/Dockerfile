FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
USER $APP_UID
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
ENV DOTNET_RUNNING_IN_CONTAINER=true
ENV Storage__UploadsPath=/tmp/filasur-uploads
ENV Storage__LogPath=/tmp/filasur-logs
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["filasur.api/filasur.api.csproj", "filasur.api/"]
COPY ["filasur.application/filasur.application.csproj", "filasur.application/"]
COPY ["filasur.infrastructure/filasur.infrastructure.csproj", "filasur.infrastructure/"]
COPY ["filasur.domain/filasur.domain.csproj", "filasur.domain/"]
RUN dotnet restore "./filasur.api/filasur.api.csproj"

COPY . .
WORKDIR "/src/filasur.api"
RUN dotnet build "./filasur.api.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./filasur.api.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
USER root
RUN mkdir -p /tmp/filasur-uploads /tmp/filasur-logs \
    && chown -R $APP_UID:$APP_UID /tmp/filasur-uploads /tmp/filasur-logs
USER $APP_UID
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "filasur.api.dll"]
