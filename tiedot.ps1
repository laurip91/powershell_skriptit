

param($komento,
[switch]$Elevated)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}







 
function salasana{

    function Get-RandomCharacters($length, $characters) { 
        $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
        $private:ofs="" 
        return [String]$characters[$random]
    }

    $password = Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 2 -characters '1234567890'
    $password += Get-RandomCharacters -length 1 -characters '!?'

    function ScrambleString([string]$inputString){     
        $characterArray = $inputString.ToCharArray()   
        $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
        $outputString = -join $scrambledStringArray
        return $outputString 
            }

            for($i = 0;$i -le 10;$i++){
                $password = scramblestring($password)

            }
            return $password

}

#csv tiedostoon viemiset
$nimi = $env:COMPUTERNAME

$tiedot = [PSCustomObject]@{
    id = 0
    pvm = get-date
    admintunnus = "[admintunnus]"
    generoitu_admin_salasana = salasana
    konenimi = $nimi    
    admintililuotu = "ei"

}

  

    
$csvpolku = $PSScriptRoot + "tiedot.csv"


if(Test-Path -Path $csvpolku){
    $tiedot_csv = import-csv -path $csvpolku
    
}


    #suorita tama skripti vain kerran, muuten tulee kaksoiskappaleita tietoihin
    function csv {
        $csv = @()
        

    if(Test-Path -Path $csvpolku){    
        $tiedot.id = $tiedot_csv.count
        $tiedot | export-csv -path $csvpolku -NoTypeInformation -Append
    }       
        else{
        $tiedot.id = 0
        $tiedot | export-csv -path $csvpolku -NoTypeInformation
    }}

    

 function admintili{
        $secure = ConvertTo-SecureString -String $tiedot.generoitu_admin_salasana -AsPlainText -force
        New-LocalUser -name $tiedot.admintunnus -Password $secure -FullName "admin2"
        try {
            $tarkistus_admin = Get-LocalUser -name "admin2"
        }
        catch {
            return $false
            #admintilia ei saatu luotua
        }
        try {
            Add-LocalGroupMember -group "järjestelmänvalvojat" -member $tiedot.admintunnus
        }
        catch {
            try {
                Add-LocalGroupMember -group "Administrators" -member $tiedot.admintunnus
            }
            catch {
                #ei voitu lisata adminryhmaan
                return $false
            }
            
        }
        
        
        


        return $true
    }

    
    if(admintili){
        $tiedot.admintililuotu = "kylla"
        csv
        write-host("Tunnukset luotu") 
        start-sleep -Seconds 2
        exit
    
    }else{write-host "virhe, ei voitu luoda paikallista admintilia"}

    
    

   
