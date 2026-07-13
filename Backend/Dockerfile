FROM mcr.microsoft.com/dotnet/sdk:8.0 AS restore
WORKDIR /src
COPY SmartStepsServer.csproj ./
RUN dotnet restore SmartStepsServer.csproj

FROM restore AS build
COPY . .
RUN dotnet build SmartStepsServer.csproj -c Release --no-restore

FROM build AS publish
RUN dotnet publish SmartStepsServer.csproj -c Release --no-build -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=publish /app/publish .

ENV PORT=8080
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

USER $APP_UID
ENTRYPOINT ["dotnet", "SmartStepsServer.dll"]
