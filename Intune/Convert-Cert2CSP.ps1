# $([System.Convert]::ToBase64String((Get-Item -Path "Cert:\CurrentUser\My\4a9981bce66db08bb677ecc939d212fd6d04e38c").RawData, 'InsertLineBreaks'))
# https://www.inthecloud247.com/add-a-certificate-to-the-trusted-publishers-with-intune-without-reporting-errors/

Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path $_ })]
        [STRING]$Certificate,
    [Parameter(Mandatory=$false)][ValidateSet("User","Device")]
        [ARRAY]$Scope = "Device",
    [Parameter(Mandatory=$true)]
    [ValidateSet("Root","CA","TrustedPublisher","TrustedPeople","UntrustedCertificates")]
        [ARRAY]$CertificateType,
    [Parameter(Mandatory=$false)][ValidateSet("File","Console")]
        [ARRAY]$Output = 'Console'
)
$Certificate = (Get-Item $Certificate).FullName
$CertificateThumbprint = ([System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Certificate)).thumbprint
$CertificateOMAURI = "./$Scope/Vendor/MSFT/RootCATrustedCertificates/$CertificateType/$CertificateThumbprint/EncodedCertificate"
$CertificateInBase64 = [System.Convert]::ToBase64String(([System.Security.Cryptography.X509Certificates.X509Certificate2]::new($Certificate)).Export('cert'))

$ScriptOutput = "Certificate Information:

 - Certificate Path: $Certificate
 - Certificate Thumbprint: $CertificateThumbprint
 - Intune OMA-URI: $CertificateOMAURI
 - Certificate in Base64 Encoding:

$CertificateInBase64
"

Switch($Output){
    'File' {
        $ScriptOutput += "`r`n-End of Certificate Information-------------------------------`r`n"
        $ScriptOutput | Out-File -FilePath $((Split-Path $certificate -leaf)+".txt") -Append
    }
    'Console' { Clear-Host; Write-Host $ScriptOutput }
    DEFAULT {}
}