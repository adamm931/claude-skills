#!/usr/bin/env bash
# Scaffolds the solution skeleton for a DDD modular monolith: the .sln, the Api host project, and
# SharedKernel. Idempotent — safe to re-run; skips anything that already exists.
#
# Usage: scaffold-solution.sh <SolutionName> <DbProvider: postgres|sqlserver> <Broker: inmemory> [OutputDir]
#
# DbProvider selects the EF Core provider package added to the Api host (also needed by every
# module's Infrastructure project — add it there too via scaffold-module.sh).
# Broker is currently always "inmemory" (MassTransit's built-in in-memory transport) — the
# architecture rule is "in-memory in the monolith, broker after split" (see architecture-rules
# skill); a real transport (RabbitMQ, Azure Service Bus, ...) is a later, deliberate migration,
# not a scaffold-time choice.
set -euo pipefail

SolutionName="${1:?Usage: scaffold-solution.sh <SolutionName> <postgres|sqlserver> <inmemory> [OutputDir]}"
DbProvider="${2:?DbProvider required: postgres|sqlserver}"
Broker="${3:-inmemory}"
OutputDir="${4:-.}"

case "$DbProvider" in
    postgres)  EfPackage="Npgsql.EntityFrameworkCore.PostgreSQL" ;;
    sqlserver) EfPackage="Microsoft.EntityFrameworkCore.SqlServer" ;;
    *) echo "Unknown DbProvider '$DbProvider' — expected postgres|sqlserver" >&2; exit 1 ;;
esac

if [[ "$Broker" != "inmemory" ]]; then
    echo "Unknown Broker '$Broker' — only inmemory is scripted today; add a transport package by hand" >&2
    exit 1
fi

mkdir -p "$OutputDir"
cd "$OutputDir"

Tfm="net$(dotnet --version | cut -d. -f1).0"
echo "-> targeting $Tfm (from installed SDK)"

solution_file_exists() {
    # dotnet new sln (SDK 9+) defaults to the .slnx format; older SDKs produce .sln — check both.
    compgen -G "./*.sln" >/dev/null 2>&1 || compgen -G "./*.slnx" >/dev/null 2>&1
}

if ! solution_file_exists; then
    dotnet new sln -n "$SolutionName"
else
    echo "-> a solution file already exists, skipping"
fi

ApiDir="src/$SolutionName.Api"
if [[ ! -f "$ApiDir/$SolutionName.Api.csproj" ]]; then
    dotnet new webapi -n "$SolutionName.Api" -o "$ApiDir" --use-controllers false -f "$Tfm"
    rm -f "$ApiDir"/WeatherForecast.cs
else
    echo "-> $SolutionName.Api already exists, skipping"
fi

SkDir="src/$SolutionName.SharedKernel"
if [[ ! -f "$SkDir/$SolutionName.SharedKernel.csproj" ]]; then
    dotnet new classlib -n "$SolutionName.SharedKernel" -o "$SkDir" -f "$Tfm"
    rm -f "$SkDir"/Class1.cs
    TemplateDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/init-ddd/templates" && pwd)"
    sed "s/{{SolutionName}}/$SolutionName/g" "$TemplateDir/SharedKernel.cs.template" > "$SkDir/SharedKernel.cs"
    # SharedKernel defines the Result pattern, the custom ICommand/IQuery messaging + ValidationDecorator
    # (FluentValidation), and the IEndpoint / CustomResults web helpers — so it needs the ASP.NET Core
    # shared framework (there is no `dotnet add` for a FrameworkReference; inject it into the csproj).
    SkCsproj="$SkDir/$SolutionName.SharedKernel.csproj"
    dotnet add "$SkCsproj" package FluentValidation
    if ! grep -q "Microsoft.AspNetCore.App" "$SkCsproj"; then
        sed -i 's#</Project>#  <ItemGroup>\n    <FrameworkReference Include="Microsoft.AspNetCore.App" />\n  </ItemGroup>\n</Project>#' "$SkCsproj"
    fi
else
    echo "-> $SolutionName.SharedKernel already exists, skipping"
fi

dotnet sln add "$ApiDir/$SolutionName.Api.csproj" "$SkDir/$SolutionName.SharedKernel.csproj" >/dev/null

dotnet add "$ApiDir/$SolutionName.Api.csproj" reference "$SkDir/$SolutionName.SharedKernel.csproj"

echo "-> adding base packages to $SolutionName.Api"
dotnet add "$ApiDir/$SolutionName.Api.csproj" package "$EfPackage"
dotnet add "$ApiDir/$SolutionName.Api.csproj" package MassTransit

echo "-> solution skeleton ready: $ApiDir, $SkDir"
echo "-> next: new-module skill / scaffold-module.sh for the first module"
