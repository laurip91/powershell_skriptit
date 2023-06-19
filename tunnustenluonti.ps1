<#
.SYNOPSIS
AD Tilin luomista helpottamaan tarkoitettu skripti

Jos antamissasi tiedoissa on virheitä, esim jos kurssi OU:ta ei löydy, tunnusten luonti lakkaa siihen.

 -Verbose -v
 -Manual -m
 -esimerkki
 -varmistus
 -info -i


    

.DESCRIPTION
Tekijä: Lauri Partanen





#>

param(  [alias('v')][switch]$verbose,
        [switch]$esimerkki,
        [alias('m')][switch]$manual,
        [switch]$varmistus,
        [alias('i')][switch]$info,
        [alias('h')][switch]$hae,
        [switch]$debug
      )



      

##############
#skriptin käytettävyyteen ja muuhun liittyvät funktiot
#yksinkertaisempi tapa tehdä tämä
#virhe ilmoitukset ilmoitetaan joka tapauksessa.
function verbose{
param($teksti)
if($verbose){
echo($teksti)
}}#



#tämä näyttää kivemman lähtölaskennan skriptin loppumiselle
#Se ilmoittaa samalla myös mitä $virhe muuttujassa on, jos on mitään.

function error_exit{
if($virhe -ne ""){virheilmoitus -ilmoitus $virhe}

for ($i=3; $i -ge 1; $i--) {
    #Write-Progress -Activity "Suljetaan" -Status $i
    write-host "Suljetaan ::: $i`r" -NoNewline
    Start-Sleep -Seconds 1
    
}
exit 1
}#

##Tämä funktio näyttää virheilmoitukset. Tähän voi myös muokata niitä sellaisiseksi kuin haluaa.
#Toimii parhaiten, jos virheet kerätään $virhe muuttujaan += . Parametri alustetaan aina skriptin aluksi.
$virhe = ""
function virheilmoitus{
param($ilmoitus)
echo "############"
echo "::VIRHEET::"
echo($ilmoitus)
echo ""
echo "#################"

}#


#Tämä funktio kertoo tietoja skriptistä
function info
{
echo "Komentorivi komennot ovat: `n
      `n
     -verbose -v   --- Skripti kertoo mitä tapahtuu `n
     -manual -m    --- Anna manuaalisesti yhden tilin tiedot `n
     -info -i      --- Yksinään, näyttää tämän infon`n
     -hae -h       --- Hae tietoja AD:sta. Hyvä esimerkiksi jos haluat tarkistaa onko OU tai tili olemassa jo. `n
     -esimerkki    --- Luo skriptin suorituskansioon esimerkki tilitiedot.txt `n
     -varmistus    --- Ilman tätä skripti vain kokeilee tilien luomista annetuilla tiedoilla.`n
     
     Muista käyttää -varmistus komentoa, kun haluat oikeasti luoda tilejä.  `n
     Voit esikatsella luotavan tilin tietoja käyttämällä -i -v . -i -v -m näyttää manuaalisesti luomasi tilin tiedot. `n

     Laita tilitiedot.txt tiedosto samaan kansioon skriptin kanssa luodaksesi useamman tunnuksen kerralla.`n
     tilitiedot.txt formaatti on:`n"

     echo("etunimi;sukunimi;puhelinnumero;kurssi;etäkirjautuja(vapaaehtoinen)`netunimi2;sukunimi2;puhelinnumero2;kurssi2;etäkirjautuja2(vapaaehtoinen)")
     echo("tilitiedot.txt ei saa olla tyhjiä rivejä!!")

     
     
}#

############



#tässä tehdään alustukset ja kaikki muut mitä pitää ihan aluksi tehdä.

#debug
#$verbose = $true



#skripti tarvitsee ActiveDirectory moduulin. 
#Tarkistetaan onko sitä saatavilla ja kokeillaan ottaa se käyttöön.
#Jos moduulia ei ole asennettuna, skripti antaa linkin ohjeeseen miten se asenetaan.
#


if(get-module -ListAvailable -name "ActiveDirectory"){

try{import-module ActiveDirectory | Write-Progress -Activity "Ladataan ActiveDirectory moduulia"
}
catch{
echo("VIRHE: Ei voitu ladata ActiveDirectory moduulia:")
echo($_.Exception.Message)
error_exit
}
}else{
Echo "ActiveDirectory moduulia ei ole asennettu."
Echo("")
Echo("Asenna Remote Server Administration Tools(RSAT) pakettikäyttääksesi skriptiä.
Ohje: https://learn.microsoft.com/fi-FI/troubleshoot/windows-server/system-management-components/remote-server-administration-tools
")
error_exit 
}








$skriptipolku = Split-Path -Parent $MyInvocation.MyCommand.Path

#luodaan tietueet tilille. Sen voisi kai tehdä jollain muullakin tapaa, mutta tämä on minusta selkein tälläkertaa.
class tilitiedot{
    


    [string]$etunimi
    [string]$sukunimi
    [string]$käyttäjänimi
    [string]$näyttönimi
    [string]$nimi
   
    [string]$kurssi
    [string]$kuvaus
    [string]$puhelin
    
        
    [string]$email
    [string]$proxy    
    [string]$etäkirjautuja
    [string]$ou
      

    }
class pakolliset_tiedot{
    [string]$etunimi
    [string]$sukunimi
    [string]$puhelinnumero
    [string]$kurssi
    [string]$etäkirjautuja
    
}

#####################


##Tässä määritellään skriptille pysyvät arvot
##Ja tehdään perus tarkistukset.

$palvelin ="[]"

#testataan yhteys palvelimeen
$testaayhteys = Test-Connection $palvelin -count 1
if($testaayhteys -eq $null){
$testaayhteys = Test-Connection $palvelin -count 3
    if($testaayhteys -eq $null){
    $virhe += "VIRHE: Ei saa yhteyttä $palvelin osoitteeseen.`n"
    
    error_exit
    }}



#määritellään mistä tilitiedot haetaan.

$tilitiedotTXT = "\tilitiedot.txt"
if(Test-Path -Path ($skriptipolku + $tilitiedotTXT)){
$polku = $skriptipolku + $tilitiedotTXT
}else{
$polku = $null
} 



#$debug = "[]"
if($debug){
echo("!!!DEBUG!!!")
$polku = "C:\temp\testaus\tilitiedot.txt"
}

##Tässä luetaan tilitiedot.txt
##jos tiedostoss aon tyhjiä rivejä,                                                    tämän pitäisi jättää ne pois
##muuten skripti heittää virheitä ja menee sekaisin, kun muualla se ei osaa käsitellä tyhjiä arvoja tuossa kohtaa.
if($polku){
$tietolähde = [IO.File]::ReadAllLines($polku,[Text.Encoding]::GetEncoding(65001)) | ForEach-Object {if($_ -ne ""){$_}}
}else{

if(-not($manual)){
$virhe += "tilitiedot.txt ei löydy. Tarkista onko se samassa kansiossa skriptin kanssa.`n"
echo 
error_exit
}}

#debug
#$tietolähde = [IO.File]::ReadAllLines($debug,[Text.Encoding]::GetEncoding(65001))

##################
# työkalu funktiot


#varmistetaan että tietolähteessä on jotain.
#Jos tehdään tiliä käsin tai halutaan tehdä esimerkkitiedosto, tämä sivutetaan.
if(($tietolähde).Length -eq 0 -and (-not($manual))-and(-not($esimerkki))){
$virhe += "VIRHE: Tyhjä tietolähde`n"
echo 
info
read-host("Paina jotain jatkaaksesi")
error_exit
}



#Tämä funktio hakee tietoja AD:sta. 
#Lisää omat juttusi += $hakutiedot muuttujaan.
#Laita hakusi try{} komennon sisään, niin funktio antaa tuloksia vain jos löytää niitä.
#Kirjoita haullesi $virhe, että käyttäjä tietää mitä haku ei löytänyt, jos -v on päällä. 
function hae_tietoja{
param($hakuteksti)
$hakutiedot = ":::Tulokset:::`n"
$suodatin = "Name -like '*" + $hakuteksti + "*'"

try{
$hakutiedot += (Get-ADUser -Filter $suodatin | Select-Object -ExpandProperty userprincipalname)+"`n"
}catch{
$virhe += "Ei löydy käyttäjää tällä nimellä `n"

}

try{
$hakutiedot += (Get-ADOrganizationalUnit -Filter {Name -eq $hakuteksti} | Select-Object -ExpandProperty Distinguishedname)+"`n"
}catch{$virhe += "Ei löydy OU:ta tällä haulla.`n"}

verbose -teksti (virheilmoitus -ilmoitus $virhe)
$virhe = ""

return $hakutiedot

}#





#Tämä funktio tekee esimerkki tilitiedot.txt tiedoston. Se myös varmistaa että sitä ei ole jo olemassa.

function esimerkkitiedosto{
$esimerkkiformaattitiedosto = $polku
$esimerkkitiedostoformaatti ="etunimi;sukunimi;puhelinnumero;kurssi;etäkirjautuja(vapaaehtoinen)`netunimi2;sukunimi2;puhelinnumero2;kurssi2;etäkirjautuja2(vapaaehtoinen)"
if(Test-Path -Path $esimerkkiformaattitiedosto){echo "Tiedosto on jo olemassa" break}else{
set-content -path $esimerkkiformaattitiedosto -value $esimerkkitiedostoformaatti
}}#




#tämä funktio poistaa ääkköset ja joitain muita erikoismerkkejä ja muuttaa ne "tavallisiksi"
#tähän voi myös helposti lisätä uusia erikois kirjaimia -> liitä vain jonon perälle samalla tyylillä kuin muutkin.
function poistakirjain{
param($asia)
$korjattu = $asia.replace("ä","a").replace("ö","o").replace("Ä","A").replace("Ö","O").replace("å","a").replace("Å","A").replace("á","a").replace("Á","A").replace("à","a").replace("À","A").replace("Ò","O").replace("ò","o").replace("Ó","O").replace("ó","ó")
return $korjattu
}#


#Tämä funktio kysyy käyttäjältä pakolliset tiedot tilin tekemiseen
#
function manuaalinen_tietojen_haku{
    
    $tiedot = [pakolliset_tiedot]::new()
    $tiedot.etunimi = read-host("Etunimi:")
    $tiedot.sukunimi = read-host("Sukunimi:")
    $tiedot.kurssi = read-host("kurssi").ToString()
    $tiedot.puhelinnumero = read-host("Puhelinnumero").ToString()
     
    
    if( (read-host "Etäkirjautuja?? Y/N") -match "[Yy]$"){$tiedot.etäkirjautuja ="99999"}else{$tiedot.etäkirjautuja = ""}
    return $tiedot
}#



#Tämä näyttää infon, jos käyttäjä erikseen niin haluaa
#####
if($info){
info
Read-Host("Paina jotain jatkaaksesi")
     exit 0
}
######

##########


#Prosessi funktiot


#tämä funktio lukee tilitiedot.txt saadut tiedot ja laittaa kunkin tilin tiedot array muuttujaan omana kokonaisuutenaan.
function käsitteleulkoisettiedot{
            

            $accounts = @()
            $content = $tietolähde
            

           


                foreach ($line in $content) {
                $accountLines = $line.Split("`n")
                
                foreach ($accountLine in $accountLines){

                    $fields = $accountLine.Split(";")
                    $etunimi = $fields[0].Trim()
                    $sukunimi = $fields[1].Trim()
                    $kurssi = $fields[3].Trim()
                    $puhelinnumero = $fields[2].Trim()
                    if ($fields[4]){$etäkirjautuja = "99999"}else{$etäkirjautuja = ""}  
                    $account = [pakolliset_tiedot]::new()
                    $account.etunimi = $etunimi
                    $account.sukunimi = $sukunimi
                    $account.kurssi = $kurssi
                    $account.puhelinnumero = $puhelinnumero
                    $account.etäkirjautuja = $etäkirjautuja
                    $accounts += $account
                    }
}
$tilit = $accounts
return @($tilit)
}#
$testaustiedot = käsitteleulkoisettiedot


###
#$testitiedot_tilit = käsitteleulkoisettiedot
#$testitiedot_manuaali_tilit = manuaalinen_tietojen_haku
###

#Tämä funktio luo kokonaiset tilitiedot annettujen pakollisten tietojen perusteella.
#Se myös tarkistaa löytyykö ad:sta OU joka on samalla nimellä kuin annettu kurssi. Jos ei löydy niin kohta jätetään tyhjäksi, mikä aiheuttaa ongelmia myöhemmin
#eli varmista että antamasi kurssinumero on oikein ja että ad:ssa on sille sopiva OU
#pidä myös huoli että ad:ssa ei ole monta OU:ta samalla kurssi numerolla.

function luo_tilitiedot{
    param($tiedot)


if($tiedot.etäkirjautuja -eq "99999"){$etäkirjautujakuvaus = "etäkirjautuja"}else{$etäkirjautujakuvaus = ""}



$tilitiedot = [tilitiedot]::new()

$tilitiedot.sukunimi = $tiedot.sukunimi
$tilitiedot.etunimi = $tiedot.etunimi

$tilitiedot.nimi = (poistakirjain $tiedot.etunimi) +"."+ (poistakirjain $tiedot.sukunimi)
$tilitiedot.käyttäjänimi = $tilitiedot.nimi.ToLower()
$tilitiedot.näyttönimi = $tiedot.etunimi + " " + $tiedot.sukunimi


$tilitiedot.kurssi = $tiedot.kurssi.ToString()
$tilitiedot.kuvaus = $tiedot.kurssi + " $etäkirjautujakuvaus"

$tilitiedot.email = $tilitiedot.käyttäjänimi + "[@jotain.fi]"
$tilitiedot.proxy = "SMTP:"+$tilitiedot.email

$tilitiedot.puhelin = $tiedot.puhelinnumero
if($tilitiedot.puhelin[0] -eq "0"){$tilitiedot.puhelin = $tilitiedot.puhelin.Substring(1)}
$tilitiedot.puhelin = ("+358") + $tilitiedot.puhelin

$tilitiedot.etäkirjautuja = $tiedot.etäkirjautuja


try{
$ou = Get-ADOrganizationalUnit -Filter {Name -eq $tiedot.kurssi} | Select-Object -ExpandProperty Distinguishedname
}catch{$tilitiedot.ou = ""}
if($ou -eq ""){$tilitiedot.ou = $false}else{$tilitiedot.ou = $ou}


return $tilitiedot

}#



#tämä funktio luo käyttäjän.
#jos pyörität skriptin ilman -varmistus argumenttia tämä vain kokeilee pystyykö tilin luomaan.
#olematonta tiliä ei voi liittää ryhmään, joten tämä antaa virheitä uusien tilien ryhmään liittämisen kokeilussa.
function luokäyttäjä{
param($tilitiedot)
$tilitiedot1 = $tilitiedot
$userprincipalname1 = (($tilitiedot1.käyttäjänimi)+"@jotain.fi")
if($tilitiedot1 -eq $null){
$virhe += "VIRHE: ei voi luoda tiliä ilman tietoja`n"
echo 
exit 1
}


if($varmistus){
verbose(("Kokeillaan luoda käyttäjätiliä "+$tilitiedot1.käyttäjänimi))
verbose("Käytettävä OU on:"+ $tilitiedot1.ou)
try{
#käyttää väliaikaista salasanaa jonka käyttäjän pitää vaihtaa heti ensimmäisen kirjautumisen yhdeydessä
#vanha käytäntö
new-ADUser -ChangePasswordAtLogon $true -Name $tilitiedot1.nimi -UserPrincipalName $userprincipalname1 -AccountPassword (ConvertTo-SecureString "[]" -AsPlainText -Force) -Enabled $true -Department $tilitiedot1.kurssi -Description $tilitiedot1.kuvaus -EmailAddress $tilitiedot1.email -PostalCode $tilitiedot1.etäkirjautuja -MobilePhone $tilitiedot1.puhelin -Surname $tilitiedot1.sukunimi -GivenName $tilitiedot1.etunimi -OtherAttributes @{'proxyaddresses' = $tilitiedot1.proxy} -DisplayName $tilitiedot1.näyttönimi -path $tilitiedot1.ou -PassThru 
verbose("Luotiin käyttäjätili $tilitiedot1.nimi")
}
catch{
$virhe += "VIRHE: Ei voitu luoda uutta käyttäjää.`n $($_.Exception.Message)`n"
echo ("Virhe luotaessa käyttäjää "+ $tilitiedot1.nimi)
virheilmoitus -ilmoitus $virhe
$virhe = ""

}


try{
verbose("Lisättiin käyttäjä $tilitiedot1.nimi [] ryhmään.")
Add-ADGroupMember -Identity "[]" -Members $tilitiedot1.käyttäjänimi}

catch{
$virhe += "VIRHE: Ei voitu lisätä ryhmään.`n $($_.Exception.Message)`n"
virheilmoitus -ilmoitus $virhe
echo ("Ei voitu lisätä ryhmään käyttäjää:"+$tilitiedot1.nimi)
$virhe = ""

}}

else{
verbose(("Kokeillaan luoda käyttäjätiliää "+$tilitiedot1.käyttäjänimi))
verbose(("Käytettävä OU on: $tilitiedot1.ou"))
verbose("")
try{

new-ADUser -WhatIf -Name $tilitiedot1.nimi -UserPrincipalName $userprincipalname1 -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString "[]" -AsPlainText -Force) -Enabled $true -Department $tilitiedot1.kurssi -Description $tilitiedot1.kuvaus -EmailAddress $tilitiedot1.email -PostalCode $tilitiedot1.etäkirjautuja -MobilePhone $tilitiedot1.puhelin -Surname $tilitiedot1.sukunimi -GivenName $tilitiedot1.etunimi -OtherAttributes @{'proxyaddresses' = $tilitiedot1.proxy} -DisplayName $tilitiedot1.näyttönimi -path $tilitiedot1.ou -PassThru 
verbose(("Kokeiltiin luoda Käyttäjätili: "+ $tilitiedot1.käyttäjänimi+" onnistuneesti"))
}
catch{
if($_.Exception.Message -contains "Cannot validate argument on parameter 'Path'. The argument is null or empty. Provide an argument that is not null or empty, and then try the command again.")
{$virhe += "VIRHE: Ei löydy OU:ta tuolla nimellä.`n"}

$virhe += "VIRHE: Ei voitu edes kokeilla luoda uutta käyttäjää.`n $($_.Exception.Message)`n"

error_exit
}




verbose(("Kokeillaan lisätä käyttäjätili "+$tilitiedot1.käyttäjänimi+ " [] ryhmään."))
verbose("")


try{Add-ADGroupMember -WhatIf -Identity "OPISKELIJAROOLI" -Members $tilitiedot1.käyttäjänimi

verbose(("Kokeiltiin liittää käyttäjätili "+$tilitiedot1.käyttäjänimi+" [] ryhmään onnistuneesti."))
}
catch{
$virhe += "VIRHE: Ei voitu edes kokeilla lisätä ryhmään.`n $($_.Exception.Message)`n"
virheilmoitus -ilmoitus $virhe
$virhe = ""



}}}#





####
#Suoritus




#Tiedon hakeminen, jos -h on päällä.
if($hae){
do{

echo ( hae_tietoja -hakuteksti (Read-Host "Haku:"))

$kysymys = Read-Host "Hae uudestaan? Y/N:"
}
while($kysymys -match "^[Yy]$")
exit 0
}



#
if(($verbose)-and($info)){

    if($manual){
    $manuaalisettiedot = luo_tilitiedot -tiedot (manuaalinen_tietojen_haku)
    echo $manuaalisettiedot
    exit 0
        }

$tilitiedot = käsitteleulkoisettiedot
        
for($i=0;$i -le $tilitiedot.count -1;$i++){
#echo "AAA " + $i +"   "+ $tilitiedot[$i]
echo (luo_tilitiedot -tiedot $tilitiedot[$i])
}
exit 0      
}



#Jos -esimerkki, tehdään esimerkki tiedosto
if($esimerkki -and(test-path -Path $skriptipolku)){
esimerkkitiedosto 
exit 0
}

#Jos haluaa tehdä käsin yhden tilin
if($manual)
{
$manuaalisettiedot = ""
$manuaalisettiedot = luo_tilitiedot -tiedot (manuaalinen_tietojen_haku)
if($verbose){
echo("Luotavan tilin tiedot:")
echo($manuaalisettiedot)}
luokäyttäjä -tilitiedot ($manuaalisettiedot)



#lisää tähän funktion suoritus, mikä hakee tiedot luodusta käyttäjästä, verbose



exit 0
}



#OLETUS
#Luodaan yksi tai useampi käyttäjä käyttämällä tilitiedot.txt tietolähteenä
#tämä suoritetaan oletuksena, eli jos suoritat skriptin suoraan ja tilitiedot.txt on samassa kansiossa, tämä tehdään.
#tätä ei suoriteta jos -esimerkki tai -manual on käytössä koska skripti loppuu jo aiempiin funktioihin.

if($debug -eq $false){

$tilitiedot = käsitteleulkoisettiedot

if($tilitiedot.Count -eq 0){
luokäyttäjä -tilitiedot (luo_tilitiedot -tiedot $tilitiedot)
exit 0
}

else{
for($i=0;$i -le $tilitiedot.count -1;$i++){
#echo "AAA " + $i +"   "+ $tilitiedot[$i]
luokäyttäjä -tilitiedot (luo_tilitiedot -tiedot $tilitiedot[$i])
}










exit 0
}}



echo "::::DEBUG::::"






















