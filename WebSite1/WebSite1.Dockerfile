ARG CI_REGISTRY_IMAGE

FROM $CI_REGISTRY_IMAGE:builder as dependencies

RUN mkdir -p /src/packages

FROM hub.lumigame.com/base/dotnet/core/sdk:7.0-alpine AS builder

ENV NUGET_PACKAGES=/src/packages

COPY --from=dependencies $NUGET_PACKAGES/. $NUGET_PACKAGES/

WORKDIR /src

COPY *.sln .
COPY WebSite1/*.csproj ./WebSite1/

RUN dotnet nuget add source https://nuget.nexdev.net/api/v2

RUN dotnet restore -v n -r linux-x64 ./WebSite1/WebSite1.csproj

COPY WebSite1/. ./WebSite1/
WORKDIR /src/WebSite1
RUN dotnet publish -r linux-x64 --self-contained false -o /app

FROM hub.lumigame.com/base/dotnet/core/aspnet:7.0-alpine AS base

# Don’t run as root
RUN adduser --disabled-password \
  --home /app \
  --gecos '' dotnetuser && chown -R dotnetuser /app
USER dotnetuser
#

WORKDIR /app
COPY --from=builder /app .
ENV TZ="America/La_Paz" \
  ASPNETCORE_URLS=http://+:5000

ENTRYPOINT ["dotnet", "WebSite1.dll"]
