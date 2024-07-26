FROM hub.lumigame.com/base/dotnet/core/sdk:7.0-alpine AS builder

RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc \
  --create-dirs \
  -o $HOME/minio-binaries/mc \
  && chmod +x $HOME/minio-binaries/mc

ENV PATH="$PATH:$HOME/minio-binaries/"

RUN mc alias set myminio https://minio-api.nexdev.net gitlab-ci H5nF5ywy262wt881ZWpq \
  && mc admin info myminio

WORKDIR /src

COPY *.sln .
COPY WebSite1/*.csproj ./WebSite1/

RUN dotnet nuget add source https://nuget.nexdev.net/api/v2

RUN --mount=type=cache,target=/root/.nuget/packages \
  dotnet restore -v n -r linux-x64 ./WebSite1/WebSite1.csproj

COPY WebSite1/. ./WebSite1/
WORKDIR /src/WebSite1
RUN --mount=type=cache,target=/root/.nuget/packages dotnet publish -r linux-x64 --self-contained false -o /app

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
