FROM hub.lumigame.com/base/dotnet/core/sdk:8.0-alpine-25h2 AS builder
WORKDIR /src

COPY *.sln .
COPY WebSite1/*.csproj ./WebSite1/
COPY WebSite2/*.csproj ./WebSite2/
RUN dotnet nuget add source http://nuget.nexdev.net/api/v2
RUN dotnet restore -v n

COPY WebSite1/. ./WebSite1/
WORKDIR /src/WebSite1
RUN dotnet publish -r linux-x64 --self-contained false -o /app

FROM hub.lumigame.com/base/dotnet/core/aspnet:8.0-alpine-25h2 AS base

# Don’t run as root
RUN adduser --disabled-password \
  --home /app \
  --gecos '' dotnetuser && chown -R dotnetuser /app
USER dotnetuser
#

WORKDIR /app
COPY --from=builder /app .
ENV TZ="America/La_Paz"

ENTRYPOINT ["dotnet", "WebSite1.dll"]
