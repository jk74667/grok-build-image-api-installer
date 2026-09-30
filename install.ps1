param(
    [string]$InstallDir,
    [switch]$SkipImageSetup,
    [switch]$NoUserChanges
)

$ErrorActionPreference = 'Stop'

if (-not $IsWindows -and $env:OS -ne 'Windows_NT') {
    throw 'This installer requires Windows.'
}

$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCommand) {
    $wingetCommand = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCommand) {
        throw 'Git is required. Install Git for Windows, then run this command again.'
    }
    Write-Output 'Installing Git for Windows with winget...'
    & $wingetCommand.Source install --id Git.Git --exact --source winget --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw 'Git for Windows installation failed.'
    }
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        $gitCandidates = @(
            (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
            (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
        )
        $gitPath = $gitCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
        if (-not $gitPath) {
            throw 'Git was installed but git.exe was not found. Open a new PowerShell window and retry.'
        }
        $gitCommand = @{ Source = $gitPath }
    }
}

$tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\')
$checkoutDir = Join-Path $tempRoot ("grok-build-image-api-" + [guid]::NewGuid().ToString('N'))
try {
    Write-Output 'Downloading the private Grok Build package. GitHub sign-in may open.'
    & $gitCommand.Source clone --depth 1 https://github.com/jk74667/grok-build-image-api.git $checkoutDir
    if ($LASTEXITCODE -ne 0) {
        throw 'Cannot access the private package. Sign in to GitHub with an account that has repository access.'
    }

    $privateInstaller = Join-Path $checkoutDir 'scripts\install-windows.ps1'
    if (-not (Test-Path -LiteralPath $privateInstaller -PathType Leaf)) {
        throw 'The private installer is missing from the repository.'
    }
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $installArguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $privateInstaller)
    if ($InstallDir) {
        $installArguments += @('-InstallDir', $InstallDir)
    }
    if ($SkipImageSetup) {
        $installArguments += '-SkipImageSetup'
    }
    if ($NoUserChanges) {
        $installArguments += '-NoUserChanges'
    }
    & $windowsPowerShell @installArguments
    if ($LASTEXITCODE -ne 0) {
        throw 'Grok Build installation failed.'
    }

    if (-not $NoUserChanges) {
        $installedBin = if ($InstallDir) { [System.IO.Path]::GetFullPath($InstallDir) } else { Join-Path $HOME '.grok\bin' }
        $env:Path = "$installedBin;$env:Path"
        $env:GROK_DISABLE_AUTOUPDATER = '1'
        foreach ($variableName in @('PACKY_IMAGE_BASE_URL', 'PACKY_IMAGE_API_KEY', 'PACKY_IMAGE_MODEL')) {
            $value = [Environment]::GetEnvironmentVariable($variableName, 'User')
            if ($value) {
                Set-Item -Path "Env:$variableName" -Value $value
            }
        }
    }
} finally {
    $resolvedCheckoutDir = [System.IO.Path]::GetFullPath($checkoutDir)
    if (-not $resolvedCheckoutDir.StartsWith("$tempRoot\", [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Refusing to remove an installer directory outside the temporary folder.'
    }
    if (Test-Path -LiteralPath $resolvedCheckoutDir) {
        Remove-Item -LiteralPath $resolvedCheckoutDir -Recurse -Force
    }
}
