Param(
	[ValidateSet("SHA1","SHA265","SHA512")]
	 [String]$HashAlgorithm = "SHA512",
	[ValidateScript({ Test-Path $_ })]
	 [String]$File = $null
)
Try{
	#$TimestampServer = "http://timestamp.comodoca.com/authenticode"
    $TimestampServer = "http://timestamp.verisign.com/scripts/timstamp.dll"
	$Certificate = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert
	if($Certificate){
		Set-AuthenticodeSignature -Certificate $Certificate -IncludeChain all -TimestampServer $TimestampServer -HashAlgorithm $HashAlgorithm -FilePath $File
	}
}Catch{
    write-host "Oops, we ran into an issue, please debug me! Error: $_"
	$_.Exception.Message
    Break
}