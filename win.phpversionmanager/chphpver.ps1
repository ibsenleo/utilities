$phpbasedir = "C:\Program Files\Devel\PHP"
$phpver = $args[0]
$phppath=$Env:PHP_ENV
$newver = $null

$installed=Get-ChildItem -Path $phpbasedir | Sort-Object


if ($null -eq $phpver) {
    Write-Host "PHP version has to be the first parameter."
    exit
}
if ($null -eq $phppath) {
    Write-Host "$PHP_ENV variable does not exist."
    exit
}

#Check installed versions and match input with some
foreach ($v in $installed) {
    if ($v.BaseName -like "php-"+$phpver+"*") {
        Write-Host "Found" $v.BaseName
        $newver = $v.BaseName
    }
}
if ($null -eq $newver) {
    Write-Host "There is no version match. Check installed versions of PHP"
    exit
}


if (Test-Path -Path $phppath) {
    Remove-Item $phppath -Recurse -Confirm:$False -Force
}

New-Item -Path "C:\Program Files\Devel\PHP\php-current" -Type SymbolicLink -Value "C:\Program Files\Devel\PHP\$newver"