FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:7.0 AS builder
WORKDIR /src

ARG TARGETPLATFORM

COPY *.sln .
COPY WebSite1/*.csproj ./WebSite1/

RUN dotnet nuget add source https://nuget.nexdev.net/api/v2
RUN dotnet restore -v n

COPY WebSite1/. ./WebSite1/
WORKDIR /src/WebSite1
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
  RID=linux-x64 ; \
  elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  RID=linux-arm64 ; \
  fi \
  && dotnet publish -r $RID --self-contained false -o /app

FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base

# Don’t run as root
RUN adduser --disabled-password \
  --home /app \
  --gecos '' dotnetuser && chown -R dotnetuser /app
USER dotnetuser
#

WORKDIR /app
COPY --from=builder /app .

ENV ASPNETCORE_URLS=http://+:5000 \
  TZ="America/La_Paz"

ENTRYPOINT ["dotnet", "WebSite1.dll"]
