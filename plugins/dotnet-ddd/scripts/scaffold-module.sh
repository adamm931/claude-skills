#!/usr/bin/env bash
# Scaffolds a bounded-context module as four projects (Public, Domain, Application, Infrastructure),
# wires their references per the architecture rules, drops in Module.cs + DbContext.cs from
# templates, and references the module's Infrastructure project from the Api host. Idempotent —
# safe to re-run; skips anything that already exists.
#
# Usage: scaffold-module.sh <SolutionRootDir> <SolutionName> <ModuleName> <DbProvider: postgres|sqlserver>
#
# Reference graph (see architecture-rules skill):
#   Domain         -> SharedKernel
#   Application    -> Domain, Public
#   Infrastructure -> Domain, Application, Public
#   Api            -> Infrastructure (for Add<Name>Module — <Name>DbContext is internal, so this
#                      composition root must live in the same assembly as it) AND Application (for
#                      Map<Name>Endpoints, once added via vertical-slice — endpoints construct
#                      Application's internal Command/Query types directly, so *that* composition
#                      root must live in Application's own assembly; Infrastructure having a project
#                      reference to Application does NOT make Application's internal types visible
#                      to code written in Infrastructure — internal doesn't cross assembly
#                      boundaries even through a reference chain). Never Domain/Public directly.
set -euo pipefail

SolutionRootDir="${1:?Usage: scaffold-module.sh <SolutionRootDir> <SolutionName> <ModuleName> <postgres|sqlserver>}"
SolutionName="${2:?SolutionName required}"
ModuleName="${3:?ModuleName required}"
DbProviderArg="${4:?DbProvider required: postgres|sqlserver}"

case "$DbProviderArg" in
    postgres)  EfPackage="Npgsql.EntityFrameworkCore.PostgreSQL"; EfMethod="Npgsql" ;;
    sqlserver) EfPackage="Microsoft.EntityFrameworkCore.SqlServer"; EfMethod="SqlServer" ;;
    *) echo "Unknown DbProvider '$DbProviderArg' — expected postgres|sqlserver" >&2; exit 1 ;;
esac

cd "$SolutionRootDir"

if ! compgen -G "./*.sln" >/dev/null 2>&1 && ! compgen -G "./*.slnx" >/dev/null 2>&1; then
    echo "No solution file found in $SolutionRootDir — run scaffold-solution.sh first" >&2
    exit 1
fi

Tfm="net$(dotnet --version | cut -d. -f1).0"
SkDir="src/$SolutionName.SharedKernel"
SkProj="$SkDir/$SolutionName.SharedKernel.csproj"
if [[ ! -f "$SkProj" ]]; then
    echo "SharedKernel project not found at $SkProj — run scaffold-solution.sh first" >&2
    exit 1
fi

ModuleRoot="src/Modules/$ModuleName"
PublicDir="$ModuleRoot/$SolutionName.$ModuleName.Public"
DomainDir="$ModuleRoot/$SolutionName.$ModuleName.Domain"
AppDir="$ModuleRoot/$SolutionName.$ModuleName.Application"
InfraDir="$ModuleRoot/$SolutionName.$ModuleName.Infrastructure"

create_classlib() {
    local dir="$1" name="$2"
    if [[ ! -f "$dir/$name.csproj" ]]; then
        dotnet new classlib -n "$name" -o "$dir" -f "$Tfm"
        rm -f "$dir"/Class1.cs
    else
        echo "-> $name already exists, skipping"
    fi
}

create_classlib "$PublicDir" "$SolutionName.$ModuleName.Public"
create_classlib "$DomainDir" "$SolutionName.$ModuleName.Domain"
create_classlib "$AppDir" "$SolutionName.$ModuleName.Application"
create_classlib "$InfraDir" "$SolutionName.$ModuleName.Infrastructure"

PublicProj="$PublicDir/$SolutionName.$ModuleName.Public.csproj"
DomainProj="$DomainDir/$SolutionName.$ModuleName.Domain.csproj"
AppProj="$AppDir/$SolutionName.$ModuleName.Application.csproj"
InfraProj="$InfraDir/$SolutionName.$ModuleName.Infrastructure.csproj"

dotnet sln add "$PublicProj" "$DomainProj" "$AppProj" "$InfraProj" >/dev/null

dotnet add "$DomainProj" reference "$SkProj"
dotnet add "$AppProj" reference "$DomainProj" "$PublicProj"
dotnet add "$InfraProj" reference "$DomainProj" "$AppProj" "$PublicProj"

echo "-> adding packages"
dotnet add "$AppProj" package MediatR
dotnet add "$AppProj" package FluentValidation
dotnet add "$InfraProj" package "$EfPackage"
dotnet add "$InfraProj" package MassTransit.EntityFrameworkCore
dotnet add "$InfraProj" package FluentValidation.DependencyInjectionExtensions

# Application hosts Map<Name>Endpoints (see reference-graph note above), so it needs ASP.NET Core's
# routing types. `dotnet add package` has no CLI form for a FrameworkReference — it's an MSBuild
# item with no NuGet equivalent — so this is inserted directly, once (idempotent on re-run).
if ! grep -q 'FrameworkReference Include="Microsoft.AspNetCore.App"' "$AppProj"; then
    sed -i 's#</Project>#\n  <ItemGroup>\n    <FrameworkReference Include="Microsoft.AspNetCore.App" />\n  </ItemGroup>\n\n</Project>#' "$AppProj"
fi

TemplateDir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../skills/new-module/templates" && pwd)"
LowerName="$(echo "$ModuleName" | tr '[:upper:]' '[:lower:]')"

MarkerFile="$AppDir/ApplicationAssemblyMarker.cs"
if [[ ! -f "$MarkerFile" ]]; then
    sed -e "s/{{Sln}}/$SolutionName/g" -e "s/{{Name}}/$ModuleName/g" \
        "$TemplateDir/ApplicationAssemblyMarker.cs.template" > "$MarkerFile"
else
    echo "-> $MarkerFile already exists, skipping"
fi

DbContextFile="$InfraDir/${ModuleName}DbContext.cs"
if [[ ! -f "$DbContextFile" ]]; then
    sed -e "s/{{Sln}}/$SolutionName/g" -e "s/{{Name}}/$ModuleName/g" -e "s/{{name}}/$LowerName/g" \
        "$TemplateDir/DbContext.cs.template" > "$DbContextFile"
else
    echo "-> $DbContextFile already exists, skipping"
fi

ModuleFile="$InfraDir/${ModuleName}Module.cs"
if [[ ! -f "$ModuleFile" ]]; then
    sed -e "s/{{Sln}}/$SolutionName/g" -e "s/{{Name}}/$ModuleName/g" -e "s/{{DbProvider}}/$EfMethod/g" \
        "$TemplateDir/Module.cs.template" > "$ModuleFile"
else
    echo "-> $ModuleFile already exists, skipping"
fi

ApiProj="src/$SolutionName.Api/$SolutionName.Api.csproj"
if [[ -f "$ApiProj" ]]; then
    dotnet add "$ApiProj" reference "$InfraProj" "$AppProj"
else
    echo "NOTE: $ApiProj not found — add references to Infrastructure and Application by hand once the Api host exists" >&2
fi

echo "-> module scaffolded: $ModuleRoot"
echo "-> register in the Api host Program.cs:"
echo "     builder.Services.Add${ModuleName}Module(builder.Configuration);"
echo "     app.Map${ModuleName}Endpoints();   # once added via the vertical-slice skill"
