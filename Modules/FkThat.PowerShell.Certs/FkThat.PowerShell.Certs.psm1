function New-SelfSignedCA {
    [CmdletBinding()]
    [OutputType([Microsoft.CertificateServices.Commands.Certificate])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name
    )

    New-SelfSignedCertificate `
        -DnsName $Name `
        -KeyLength 2048 `
        -KeyAlgorithm 'RSA' `
        -HashAlgorithm 'SHA256' `
        -KeyExportPolicy 'Exportable' `
        -NotAfter (Get-Date).AddYears(5) `
        -CertStoreLocation 'Cert:\CurrentUser\My' `
        -KeyUsage 'CertSign', 'CRLSign'
}

function New-SelfSignedCert {
    [CmdletBinding()]
    [OutputType([Microsoft.CertificateServices.Commands.Certificate])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [Microsoft.CertificateServices.Commands.Certificate]
        $CA
    )

    New-SelfSignedCertificate `
        -DnsName $Name
        -Signer $CA `
        -KeyLength 2048 `
        -KeyAlgorithm 'RSA' `
        -HashAlgorithm 'SHA256' `
        -KeyExportPolicy 'Exportable' `
        -NotAfter (Get-Date).AddYears(2) `
        -CertStoreLocation 'Cert:\CurrentUser\My'
}

# $password = Read-Host -AsSecureString "Password: "
# Export-Certificate -Cert $caCert -FilePath $caCrtFile -Force | Out-Null
# Import-Certificate -CertStoreLocation 'Cert:\CurrentUser\Root' -FilePath $caCrtFile
# Export-PfxCertificate $cert "${domain}.pfx" -Password $password -Force | Out-Null
