param(
    [string]$CertificateThumbprint = '',
    [string]$CertificatePath = '',
    [securestring]$CertificatePassword = (ConvertTo-SecureString 'password' -AsPlainText -Force),
    [string]$Publisher = 'CN=Aptlantis Development',
    [switch]$SkipBuild,
    [string]$Executable = 'target\release\sesm-desktop.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
Push-Location -LiteralPath $projectRoot
$certificate = $null
try {
    if ($CertificatePath -and $CertificateThumbprint) { throw 'Choose either CertificatePath or CertificateThumbprint, not both.' }
    $resolvedCertificatePath = $null
    if ($CertificatePath) {
        $resolvedCertificatePath = (Resolve-Path -LiteralPath $CertificatePath).Path
        # Ephemeral loading inspects the PFX without importing a private key or changing certificate trust.
        $certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $resolvedCertificatePath, $CertificatePassword,
            [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
        )
    } elseif ($CertificateThumbprint) {
        if ($CertificateThumbprint -notmatch '^[0-9a-fA-F]{40}$') { throw 'CertificateThumbprint must be a 40-character hexadecimal thumbprint.' }
        $certificate = Get-Item -LiteralPath ("Cert:\CurrentUser\My\" + $CertificateThumbprint)
    }
    if ($certificate) {
        if (-not $certificate.HasPrivateKey) { throw 'The signing certificate has no private key.' }
        if ((Get-Date) -lt $certificate.NotBefore -or (Get-Date) -gt $certificate.NotAfter) { throw 'The signing certificate is outside its validity period.' }
        if ($PSBoundParameters.ContainsKey('Publisher') -and $Publisher -cne $certificate.Subject) { throw 'Publisher must exactly match the signing certificate subject.' }
        $Publisher = $certificate.Subject
        Write-Output ("Development signing publisher: " + $Publisher)
    }
    if (-not $SkipBuild) {
        & npm run tauri build -- --no-bundle
        if ($LASTEXITCODE -ne 0) { throw 'Desktop build failed.' }
    }
    $projectManifest = Get-Content -LiteralPath (Join-Path $projectRoot 'SESM-Desktop.manifest.toml') -Raw
    if ($projectManifest -notmatch '(?m)^version = "([0-9]+\.[0-9]+\.[0-9]+)"') { throw 'Project manifest version is missing.' }
    $manifestVersion = $Matches[1]
    if ((Get-Content -LiteralPath (Join-Path $projectRoot 'package.json') -Raw | ConvertFrom-Json).version -ne $manifestVersion) { throw 'Frontend and project manifest versions disagree.' }
    $packageVersion = "$manifestVersion.0"
    $sdkRoot = 'C:\Program Files (x86)\Windows Kits\10\bin'
    $makeAppx = Get-ChildItem -LiteralPath $sdkRoot -Filter makeappx.exe -Recurse | Where-Object FullName -Match '\\x64\\makeappx.exe$' | Sort-Object FullName -Descending | Select-Object -First 1
    if (-not $makeAppx) { throw 'Windows SDK makeappx.exe is required.' }
    $sessionName = 'msix-' + (Get-Date -Format 'yyyyMMdd-HHmmss')
    $stage = Join-Path $projectRoot (".work\" + $sessionName)
    New-Item -ItemType Directory -Path $stage | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $stage 'Assets') | Out-Null
    $exePath = [IO.Path]::GetFullPath((Join-Path $projectRoot $Executable))
    if (-not $exePath.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Executable must stay inside this project.' }
    Copy-Item -LiteralPath $exePath -Destination (Join-Path $stage 'sesm-desktop.exe')
    foreach ($doc in @('README.md','Project-README.md','Validation-Checklist.md','LICENSE','THIRD-PARTY-NOTICES.md')) {
        Copy-Item -LiteralPath (Join-Path $projectRoot $doc) -Destination $stage
    }
    Copy-Item -LiteralPath (Join-Path $projectRoot 'docs') -Destination (Join-Path $stage 'docs') -Recurse
    # Exact-installer stage binding belongs to the external release packet, avoiding self-reference.
    Remove-Item -LiteralPath (Join-Path $stage 'docs\Release-Stage-Evidence.toml')
    # Icons are generated from the app's own code-native mark, using Factor colors.
    Copy-Item -LiteralPath (Join-Path $projectRoot 'src-tauri\icons\Square150x150Logo.png'),(Join-Path $projectRoot 'src-tauri\icons\Square44x44Logo.png'),(Join-Path $projectRoot 'src-tauri\icons\StoreLogo.png') -Destination (Join-Path $stage 'Assets')
    $safePublisher = [System.Security.SecurityElement]::Escape($Publisher)
    $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10" xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10" xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities" IgnorableNamespaces="uap rescap">
  <Identity Name="Aptlantis.SESMDesktop.Development" Publisher="$safePublisher" Version="$packageVersion" ProcessorArchitecture="x64" />
  <Properties><DisplayName>SESM Desktop Development</DisplayName><PublisherDisplayName>Aptlantis Development</PublisherDisplayName><Logo>Assets\StoreLogo.png</Logo></Properties>
  <Dependencies><TargetDeviceFamily Name="Windows.Desktop" MinVersion="10.0.19041.0" MaxVersionTested="10.0.26100.0" /></Dependencies>
  <Resources><Resource Language="en-us" /></Resources>
  <Applications><Application Id="SESMDesktop" Executable="sesm-desktop.exe" EntryPoint="Windows.FullTrustApplication"><uap:VisualElements DisplayName="SESM Desktop Development" Description="Offline SESM metadata editor" BackgroundColor="#020B14" Square150x150Logo="Assets\Square150x150Logo.png" Square44x44Logo="Assets\Square44x44Logo.png" /></Application></Applications>
  <Capabilities><rescap:Capability Name="runFullTrust" /></Capabilities>
</Package>
"@
    Set-Content -LiteralPath (Join-Path $stage 'AppxManifest.xml') -Value $xml -Encoding utf8
    $artifactDir = Join-Path $projectRoot 'target\release\bundle\msix'
    New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null
    $artifact = Join-Path $artifactDir ("SESM-Desktop-$manifestVersion-development-$sessionName.msix")
    & $makeAppx.FullName pack /d $stage /p $artifact /o
    if ($LASTEXITCODE -ne 0) { throw 'MSIX packaging failed.' }
    if ($certificate) {
        $signTool = Join-Path $makeAppx.DirectoryName 'signtool.exe'
        if ($resolvedCertificatePath) {
            $plainPassword = [System.Net.NetworkCredential]::new('', $CertificatePassword).Password
            try { & $signTool sign /f $resolvedCertificatePath /p $plainPassword /fd SHA256 $artifact }
            finally { $plainPassword = $null }
        } else {
            & $signTool sign /sha1 $CertificateThumbprint /fd SHA256 $artifact
        }
        if ($LASTEXITCODE -ne 0) { throw 'Development MSIX signing failed.' }
        $signature = Get-AuthenticodeSignature -LiteralPath $artifact
        if (-not $signature.SignerCertificate -or $signature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) { throw 'Package signer does not match the selected development certificate.' }
        $signingRecord = [ordered]@{
            version = 1
            status = 'self-signed-development'
            publisher = $certificate.Subject
            thumbprint = $certificate.Thumbprint
            artifact = $artifact
            authenticode_status = [string]$signature.Status
            trust_installed_by_script = $false
        }
        New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'evidence\local') | Out-Null
        $signingRecord | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'evidence\local\signing.json') -Encoding utf8
        [IO.File]::WriteAllBytes(
            (Join-Path $projectRoot 'evidence\local\SESM-Desktop-development.cer'),
            $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
        )
    } else {
        # Do not accidentally reuse a previous signed-package record when making an unsigned candidate.
        $signingRecord = [ordered]@{ version = 1; status = 'unsigned'; artifact = $artifact; trust_installed_by_script = $false }
        New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'evidence\local') | Out-Null
        $signingRecord | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'evidence\local\signing.json') -Encoding utf8
    }
    & node scripts/hash-artifacts.mjs $artifact $exePath
    if ($LASTEXITCODE -ne 0) { throw 'Artifact hashing failed.' }
    if (-not $certificate) { Write-Output 'Unsigned development MSIX staged. Signing and installation acceptance remain pending.' }
    else { Write-Output 'Development MSIX signed. Local certificate trust and installation acceptance are separate steps.' }
} finally {
    if ($certificate) { $certificate.Dispose() }
    Pop-Location
}
