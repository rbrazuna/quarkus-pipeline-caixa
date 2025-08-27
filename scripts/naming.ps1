# naming.ps1
# Helpers de nomenclatura para o projeto HACKATHON
# - Ambientes suportados: des, prd
# - Sequenciais independentes por ambiente
# - Estado persistido em .naming-state.json (no diretório atual)

Set-StrictMode -Version Latest

$script:NamingStatePath = Join-Path -Path (Get-Location) -ChildPath ".naming-state.json"

function Initialize-NamingState {
    if (-not (Test-Path $script:NamingStatePath)) {
        $state = @{
            des = 0  # último número emitido para DES
            prd = 0  # último número emitido para PRD
        }
        $state | ConvertTo-Json | Set-Content -Path $script:NamingStatePath -Encoding UTF8
    }
}

function Get-NamingState {
    Initialize-NamingState
    try {
        return Get-Content -Raw -Path $script:NamingStatePath | ConvertFrom-Json
    } catch {
        throw "Falha ao ler $script:NamingStatePath: $($_.Exception.Message)"
    }
}

function Save-NamingState($state) {
    $state | ConvertTo-Json | Set-Content -Path $script:NamingStatePath -Encoding UTF8
}

function Get-NextSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('des','prd')]
        [string]$Environment
    )
    $state = Get-NamingState
    $current = [int]($state.$Environment)
    $next = $current + 1
    if ($next -gt 999) { throw "Sequência para '$Environment' excedeu 999." }
    # formata 001..999
    return ('{0:000}' -f $next)
}

function Bump-Sequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('des','prd')]
        [string]$Environment,
        [Parameter(Mandatory=$true)]
        [ValidateRange(1,999)]
        [int]$Value
    )
    $state = Get-NamingState
    $state.$Environment = $Value
    Save-NamingState $state
}

function Get-InstanceName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Project,      # ex: hackathon
        [Parameter(Mandatory=$true)][string]$Product,      # ex: getting-started
        [Parameter(Mandatory=$true)][ValidateSet('des','prd')][string]$Environment,
        [Parameter(Mandatory=$true)][string]$Group,        # ex: grp01
        [int]$Seq                                          # opcional: força sequência (1..999)
    )
    # normaliza
    $proj = $Project.ToLower()
    $prod = $Product.ToLower()
    $env  = $Environment.ToLower()
    $grp  = $Group.ToLower()

    if ($PSBoundParameters.ContainsKey('Seq')) {
        if ($Seq -lt 1 -or $Seq -gt 999) { throw "Seq deve estar entre 1 e 999." }
        $num = ('{0:000}' -f $Seq)
        # opcional: se Seq manual for maior que o último conhecido, atualiza o estado
        $state = Get-NamingState
        if ([int]$state.$env -lt $Seq) {
            Bump-Sequence -Environment $env -Value $Seq
        }
    } else {
        $num = Get-NextSequence -Environment $env
        # grava o avanço
        Bump-Sequence -Environment $env -Value ([int]$num)
    }

    return "ci-$proj-$prod-$env-$grp-$num"
}

if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Initialize-NamingState,Get-NextSequence ...
}

