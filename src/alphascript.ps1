<#
	.NOTES
	    ===========================================================================
         Created on:    2019-04-05
         Created by:    Nova Dynamics - Christian Rybovic
         Sourcecode:    https://github.com/NovaDynamics/alphascript
	    ===========================================================================

	.DESCRIPTION
		Framework to manage PowerShell-Scripts.
#>

#---------------------------------------------------------[Configuration]----------------------------------------------------------

$basepath = ""                # Required
$alternativeSpaceChar = "_"   # Empty value allowed

#----------------------------------------------------------[Declarations]----------------------------------------------------------

$version = '0.4'
$scriptCounter = 0
$Host.UI.RawUI.WindowTitle = "AlphaScript"
$rawUiWidth = if ($Host.UI.RawUI.MaxWindowSize) { $Host.UI.RawUI.MaxWindowSize.Width } else { 120 }

#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Write-HostLine {
    <#
    .SYNOPSIS
        Displays a horizontal line.

    .DESCRIPTION
        The function will draw a line horizontally over the whole screen.

    #>
    process {
        Write-Host ""
        Write-Host ("").PadLeft($rawUiWidth - 1, '-')
        Write-Host ""
    }
}

function Write-HostCenter {
    <#
    .SYNOPSIS
        Writes a message centered on the screen.

    .PARAMETER Message
        Text to display centered on the screen.

    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    process {
        Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $rawUiWidth / 2) - [Math]::Floor($Message.Length / 2)))), $Message)
    }
}

function Write-HostIndented {
    <#
    .SYNOPSIS
        Writes a message indented on the screen.
        
    .PARAMETER Title
        Text displayed on the left side (not required).
        
    .PARAMETER Message
        Text displayed indented on the right side.

    .PARAMETER Indent
        Indent for the text on the right side.

    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory=$true)]
        [int]$Indent
    )
    process {
        Write-Host (($Title).PadRight(($Indent - $Title.lenght), ' ') + $Message)
    }
}

function global:Clear-Host {
    <#
    .SYNOPSIS
        Overrides the default function of Clear-Host.

    .DESCRIPTION
        The function will override the default Clear-Host, also for all calling scripts. It executes the original code of the function, but always writes a custom header afterwards.

    #>
    process {
        $RawUI = $Host.UI.RawUI
        $RawUI.CursorPosition = @{X=0;Y=0}
        $RawUI.SetBufferContents(
            @{Top = -1; Bottom = -1; Right = -1; Left = -1},
            @{Character = ' '; ForegroundColor = $rawui.ForegroundColor; BackgroundColor = $rawui.BackgroundColor})
        # .Link
        # https://go.microsoft.com/fwlink/?LinkID=225747
        # .ExternalHelp System.Management.Automation.dll-help.xml

        Write-Host ""
        Write-HostCenter "- AlphaScript -"
        Write-HostCenter "V$($version)"
        Write-HostLine
        Write-Host " " -NoNewline
        if ($activeASModule) {
            Write-Host "$($activeNavigation) > " -ForegroundColor DarkGray -NoNewline
            Write-Host $activeASModule.NAME 
        } else {
            Write-Host $activeNavigation
        }
        Write-HostLine
    }
}

function global:Read-Host {
    <#
    .SYNOPSIS
        Overrides the built-in function of Read-Host to add control of the execution flow.

    .DESCRIPTION
        The function will extend the base-functionality of Read-Host to cancel the execution of a script anytime.
        
    .PARAMETER Prompt
        Text to display.

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Prompt = '~'
    )
    process {
        if ($Prompt -ne '~') {
            Write-Host "$($Prompt):"
            $PSBoundParameters['Prompt'] = '~'
        } else {
            foreach ($key in $MyInvocation.MyCommand.Parameters.Keys) {
                $value = Get-Variable $key -ValueOnly -ErrorAction SilentlyContinue
                if ($value -and !$PSBoundParameters.ContainsKey($key)) {
                    $PSBoundParameters[$key] = '~'
                }
            }
        }
        $result = Microsoft.PowerShell.Utility\Read-Host @PSBoundParameters
        if ($activeASModule -and $result -eq 'x') {
            break moduleloop
        } else {
            $result
        }
    }
}

function Check-KeyAlreadyUsed {
    <#
    .SYNOPSIS
        Check if a key is already used.
        
    .PARAMETER Key
        Key to check.

    .PARAMETER Items
        List with items.
        
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$Key,

        [Parameter(Mandatory=$true)]
        $Items
    )
    process {
        foreach ($item in $Items) {
            if ($item.KEY -eq $Key) {
                return $true
            }
        }
        return $false
    }
}

function Get-StructureLayer {
    <#
    .SYNOPSIS
        Gets all neccessary informations for a structure layer.
                
    .PARAMETER Key
        Key to access this layer.

    .PARAMETER Name
        Name of the current structure layer.

    .PARAMETER Path
        Path of the folder.
        
    #>
    param(
        [Parameter(Mandatory=$true)]
        [int]$Key,

        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    process {
        $allSublayers = Get-ChildItem -Path $Path | ? { $_.Name -match "^\d+-.+"}
        $sublayers = @()         
        foreach ($sublayer in $allSublayers) {
            $menuKey,$menuName = $sublayer.Name -split "-",2
            if (Check-KeyAlreadyUsed -Key $menuKey -Items $sublayers) {
                Write-Host ("[WARNING] Structure layer not loaded: Key $($menuKey) is already used. ($($sublayer.FullName))") -ForegroundColor Yellow
            } else {
                $sublayers += Get-StructureLayer -Key $menuKey -Name $menuName -Path $sublayer.FullName
            }
        }
        $allItems = Get-ChildItem -Path $Path | ? { $_.Name -notmatch "^\d+-.+"}
        $items = @()
        foreach ($item in $allItems) {
            $ASModule = Get-ASModule -Name $item.Name -Path $item.FullName
            if($ASModule) {
                if (Check-KeyAlreadyUsed -Key $ASModule.KEY -Items $sublayers) {
                    Write-Host ("[WARNING] Module not loaded: Key $($ASModule.KEY) is already used for layer. ($($ASModule.MODULE.ModuleBase))") -ForegroundColor Yellow
                    continue
                }
                if (Check-KeyAlreadyUsed -Key $ASModule.KEY -Items $items) {
                    Write-Host ("[WARNING] Module not loaded: Key $($ASModule.KEY) is already used. ($($ASModule.MODULE.ModuleBase))") -ForegroundColor Yellow
                    continue
                }
                $items += $ASModule
            }
        }
        if($alternativeSpaceChar) {
            $Name = $Name.Replace($alternativeSpaceChar, ' ')
        }
        if ($items.Count -gt 0 -or $sublayers.Count -gt 0) {
            $sublayers = $sublayers | Sort-Object @{Expression={$_.KEY}; Ascending=$true}
            $items = $items | Sort-Object @{Expression={$_.KEY}; Ascending=$true}
            @{KEY = $Key; NAME = $Name; SUBLAYERS = $sublayers; ITEMS = $items}
        }
    }
}

function Get-ASModule {
    <#
    .SYNOPSIS
        Loads a AlphaScript-Module.

    .DESCRIPTION
        Checks if a given module is a valid AlphaScript-Module and loads it.

    .PARAMETER Name
        Name of the module.

    .PARAMETER Path
        Path to the module.

    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    process {
        if ((Get-Module $Name)) {
            Write-Host ("[WARNING] Module not loaded: A module with the same name is already loaded. ($($Path))") -ForegroundColor Yellow
        } else {
            $module = Get-Module $Path -ListAvailable -ErrorAction SilentlyContinue
            Import-Module $Path
            if ($module) {
                if ((Get-Command ($module.Name + "\ASConfig") -ErrorAction SilentlyContinue) -and (Get-Command ($module.Name + "\ASMain") -ErrorAction SilentlyContinue)) {
                    $ASModule = &$module\ASConfig
                    if ($ASModule.KEY -and $ASModule.NAME) {
                        $ASModule.Add("MODULE", $module)
                        $ASModule
                        $global:scriptCounter++
                    } else {
                        Write-Host ("[WARNING] Module not loaded: Wrong configuration. ($($module.ModuleBase))") -ForegroundColor Yellow
                    }
                } else {
                    Write-Host ("[WARNING] Module not loaded: Function ASConfig/ASMain is missing. ($($module.ModuleBase))") -ForegroundColor Yellow
                }
            } else {
                Write-Host ("[WARNING] Module not loaded: Invalid module. ($($Path))") -ForegroundColor Yellow
            }
        }
    }
}

function Show-StructureLayer {
    <#
    .SYNOPSIS
        Displays the current structure layer.

    .PARAMETER Layer
        The layer to display.

    .PARAMETER Navigation
        The path of the current Navigation, which will be displayed in the header.

    #>
    param(
        [Parameter(Mandatory=$true)]
        $Layer,

        [Parameter(Mandatory=$true)]
        $Navigation
    )
    process {
        $activeNavigation = $Navigation
        do {
            if ($input) {
                foreach ($sublayer in $Layer.SUBLAYERS) {
                    if ($sublayer.KEY -eq $input){
                        Show-StructureLayer -Layer $sublayer -Navigation ($Navigation + " > " + $sublayer.NAME)
                    }
                }
                foreach ($item in $Layer.ITEMS) {
                    if ($item.KEY -eq $input){
                        Invoke-ASModule $item
                    }
                }
            }
            Clear-Host
            $input = $null
            if ($Layer.SUBLAYERS.Count -gt 0) {
                Write-Host "`tCategories:"
                foreach ($sublayer in $Layer.SUBLAYERS) {
                    Write-Host "`t`t$($sublayer.KEY)`t" -ForegroundColor Cyan -NoNewline
                    Write-Host "$($sublayer.NAME)"
                }
                Write-Host ""
            }
            if ($Layer.ITEMS.Count -gt 0) {
                Write-Host "`tScripts:"
                foreach ($item in $Layer.ITEMS) {
                    Write-Host "`t`t$($item.KEY)`t" -ForegroundColor Green -NoNewline
                    Write-Host "$($item.NAME)"
                }
                Write-Host ""
            }

        } while (($input = Read-Host) -ne "x")
    }
}

function Invoke-ASModule {
    <#
    .SYNOPSIS
        Calls the script of a AlphaScript-Module.

    .DESCRIPTION
        Invokes a AlphaScript-Module and handles looping of the script automatically.

    .PARAMETER ASModule
        A valid AlphaScript-Module is needed.
        
    #>
    param(
        [Parameter(Mandatory=$true)]
        $ASModule
    )
    process {
        $activeASModule = $ASModule
        $module = $ASModule.MODULE
        :moduleloop do {
            Clear-Host
            &$module\ASMain
            Write-HostLine
            Read-Host "Press any key to rerun the script" | Out-Null
        } while ($true)
        $activeASModule = $null
    }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

if (!$basepath) {
    Write-Host "Basepath is not defined (see section 'Configuration')" -ForegroundColor Red
    pause
    exit
}
if (!(Test-Path $basepath)) {
    Write-Host "Basepath folder not exist." -ForegroundColor Red
    pause
    exit
}

Get-Module | Remove-Module
$layer = @()
$layer = Get-StructureLayer -Key 0 -Name "Base" -Path $BasePath

Write-HostLine
Write-HostCenter "--- Welcome to AlphaScript V$($version) ---"
Write-Host ""
Write-HostCenter "https://github.com/NovaDynamics/alphascript"
Write-HostLine
Write-HostIndented -Indent 20 -Title "Basepath:" -Message $basepath
Write-HostIndented -Indent 20 -Title "Total Scripts:" -Message $global:scriptCounter
Write-Host ""

if ($layer.Count -gt 0) {
    Write-Host "Note: "-NoNewline -ForegroundColor Yellow
    Write-Host "You can always navigate back by entering 'x'"
    Write-Host ""
    Read-Host "Press any key to start"
    while($true) {
        Show-StructureLayer -Layer $layer -Navigation "Main Menu"
    }
} else {
    Write-Host "No AlphaScript-Modules found/loaded." -ForegroundColor Red
    pause
}
