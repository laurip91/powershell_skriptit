#encoding: utf-8


$sis = import-csv -Path "C:\Temp\numerot.csv" -Encoding UTF8


class aztilit{
    $id
    $studentanimi
    $azadhakunimi
    $p_adhakunimi 
    $loytyymonta


}


#https://stackoverflow.com/questions/62737875/powershell-replace-special-characters-like-%C3%BC
#lahde talle funktiolle

function Replace-Diacritics {
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string] $Text
    )
    ($Text.Normalize([Text.NormalizationForm]::FormD).ToCharArray() | 
     Where-Object {[Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne 
                   [Globalization.UnicodeCategory]::NonSpacingMark }) -join ''
}









class tiedot {
    $id
    $etunimi
    $sukunimi
    $puhelinnumero    

    
}

#listaa numerot.csv sisallon perusteella. tietojen oltava muodossa:
#nimi,puhelinumero
#"sukunimi,etunimet",numero
function listaa{

        $kaikki = @()

        for($i=0;$i -lt $sis.Length;$i++){

            $kohta = [tiedot]::new()
            $kohta.id = $i
            $kohta.etunimi = $sis[$i].nimi.split(",")[1]
            $kohta.sukunimi = $sis[$i].nimi.split(",")[0]
            $kohta.puhelinnumero = $sis[$i].puhelinnumero.ToString()
            if($null -eq $kohta.etunimi -or '' -eq $kohta.etunimi ){$kohta.etunimi = "tyhja"}else{$kohta.etunimi = $kohta.etunimi.split()|where-object{$_ -ne ''}}
            if($null -eq $kohta.sukunimi -or '' -eq $kohta.sukunimi ){$kohta.sukunimi = "tyhja"}else{$kohta.sukunimi = $kohta.sukunimi.split()|where-object{$_ -ne ''}}
            
            $kaikki += $kohta
        }
        return $kaikki
}

#tarkistaa onko puhelinnumerot oikein tiedoissa
#merkitsee virheelliset numerot
#muuttaa numerot +358 muotoon
#jos numero ei ole skriptiin kirjatun standardin mukainen numeroa ei muutella ja se merkitaan, etta se erottuu
function numero_oikein{
        param($numero)

        if(($null -eq $numero) -or ($numero -eq "")){
            $korjattu ="Ei numeroa"
            return  $korjattu
        }

        if($numero -match '[\d]'){
            #sisaltaa numeron
            #voi jatkua
            
        }else{
        return "Virheellinen_numero:teksti:"+$numero 
        }
        
        
        $korjattu = $numero -replace ' ','' -replace '-',''
        #ota ylimaaraiset pois

        if($korjattu[0] -eq "0"){$korjattu = $korjattu.substring(1,$korjattu.Length-1)}
        #onko ensimmainen kirjain 0? jos on niin se otetaan pois
        
        if(($korjattu.Length -eq 9) -and ($korjattu.substring(0,4)-ne "+358")){$korjattu = "+358"+$korjattu}
        #onko 9 merkkia pitka? EikÃ¤ ole +358 alussa? sitten lisataann +358

        #puhelinnumero on 9 merkkiÃ¤ pitkÃ¤, jos ei lasketa ensimmaisesta 0
        #jos on normaalissa muodossa eli ei ole +jotain
        #ja ei ole teksti

        #jos alkaa +jotainmuutakuin358

        if($korjattu.Substring(0,1)-like "+" -and $korjattu.Substring(1,4)-ne"358" -and $korjattu.Length -eq 13 ){
            $korjattu ="+358"+ $korjattu.Substring(4,$korjattu.Length-4)
        #alkaako +? ja ei ole 358 sen jalkeen? ja on 13 merkkia pitka? sitten ensimmaiset 4 merkkia vaihdetaan +358
        }


       

        

        ###
        ##
        #onko numero
        #+358 alkuinen
        #13 merkkia
        #ei sisalla 0 +358 jÃ¤lkeen
        if ($korjattu -like "+358*" -and $korjattu.Substring(4, 1) -ne '0' -and $korjattu.Length -eq 13) {
            return $korjattu
        }else{return "Virheellinen_numero:"+ $korjattu
            
            #write-host "invalid: " + "$korjattu"

        
        
        
        
        }       

        #return $korjattu

    }
    #kay lapi listan ja tekee korjaukset
function korjaanumero{ 


        $lista11 = listaa
        for($i=0;$i -lt $lista11.Length ;$i++){
            
            $lista11[$i].puhelinnumero = (numero_oikein -numero ($lista11[$i].puhelinnumero))
            
        

        }

        return $lista11
}

#skriptin rakennusvaiheen ratkaisu. muuten skripti paivittaisi tiedot turhaan jokakerta kun sita testaa.
if($null -eq $lista0){$lista0 = listaa}
if($null -eq $lista1){$lista1 = korjaanumero}










#halusin tehda nopeasti funktion ja kaytin lyhyita nimia
#funktio yhdistaa etu ja sukunimen yhdeksi, laittaen valiin pisteen.
#jos etunimia onkin monta, funktio ottaa arrayn ensimmaisen nimen
function haenimia{
    param($e,
    $s
    )
    if ($e -is [Array]){
        $111 = $e[0]
    }
    else{$111 = $e}
    
    if ($s -is [Array]){
        $222 = [string]::Join("",$s)
    }
    else{$222 = $s}
$aaa = $111 +"."+$222
return $aaa
}



#poistaa nimilistan nimista erikoismerkit ja korvaa ne tavallisilla kirjaimilla
function nimilista{
$nimet = @()

foreach($kohta in $lista0){
    $nimi = haenimia -e $kohta.etunimi -s $kohta.sukunimi
    $nimi = $nimi.ToLower()

    $nimi = Replace-Diacritics $nimi
    $nimet += $nimi
}
return $nimet
}

if($null -eq $nimilista){$nimilista = nimilista}




#azure haku, hakee tilit annetun nimen perusteella
#jaanne, ei kaytossa
function azhaku{
    param($nimi)
    $adtilit = @()
    $adtilit += (Get-AzureADUser -SearchString $nimi).userprincipalname
    return $adtilit
}


#hakee tilit annetun hakusanalistan perusteella.
#switch case on jaanne aiemmasta ideasta, mutta se mahdollistaa myos funktion toiminnallisuuden lisaamisen myohemmin
function paikallinen_adhaku{
    param($moodi,$hakusanalista)
    $hakutulos=@()
    if($hakusanalista -is [string]){
        $haettava = "*"+$hakusanalista+"*"
        $hakutulos = Get-ADUser -Filter {userprincipalname -like $haettava} | Select-Object -property userprincipalname
        return $hakutulos.userprincipalname | select-object -Unique
        break
    }

    switch ($moodi) {
        1{  }
        
        Default {foreach($hakusana in $hakusanalista){
                $haettava = "*"+$hakusana+"*"
                $tulos = Get-ADUser -Filter {userprincipalname -like $haettava} | Select-Object -property userprincipalname
                foreach($kohta in $tulos){
                    $hakutulos += $kohta.userprincipalname
            }


        }}}
   
    return $hakutulos | select-object -Unique
   

}   





#tekoaly yliherramme antoi minulle taman funktion.
#se vertaa kahta tekstia ja antaa numeron kuinka lahella tekstit ovat toisiaan.

function Get-LevenshteinDistance {
    param (
        [string]$source,
        [string]$target
    )

    $sourceLength = $source.Length
    $targetLength = $target.Length

    $matrix = @()

    for ($i = 0; $i -le $sourceLength; $i++) {
        $row = @()
        for ($j = 0; $j -le $targetLength; $j++) {
            $row += 0
        }
        $matrix += ,$row
    }

    for ($i = 0; $i -le $sourceLength; $i++) {
        $matrix[$i][0] = $i
    }

    for ($j = 0; $j -le $targetLength; $j++) {
        $matrix[0][$j] = $j
    }

    for ($i = 1; $i -le $sourceLength; $i++) {
        for ($j = 1; $j -le $targetLength; $j++) {
            if ($source[$i - 1] -eq $target[$j - 1]) {
                $cost = 0
            } else {
                $cost = 1
            }

            $deletion = $matrix[$i - 1][$j] + 1
            $insertion = $matrix[$i][$j - 1] + 1
            $substitution = $matrix[$i - 1][$j - 1] + $cost

            $matrix[$i][$j] = [Math]::Min([Math]::Min($deletion, $insertion), $substitution)
        }
    }

    return $matrix[$sourceLength][$targetLength]
}

#luo kaikki mahdolliset yhdistelmat annetun henkilon nimista. 
#alifunktio verrattavatili2 funktiolle
function rakenna{
    param($etunimet, 
    $sukunimi)
    $yhdistelmat = @()
    foreach($etunimi in $etunimet){
        
            $yhdistelmat += "$etunimi.$sukunimi@edu.psk.fi"
        }
    return $yhdistelmat
}


#luo nimiyhdistelmat ad hakua varten.
#ottaa huomioon myos valiviivat ja kasittelee ne 
#ottaa haettavista nimista pois erikoismerkit

function verrattavatili2{
    param($i)
 $yhdistelmat = @()
$etunimet_korjattu = @()
 



  

        $etunimet = $lista1[$i].etunimi
        
        foreach($etunimi in $etunimet){
            
            $etunimet_viivalla += $etunimi.split("-")
            $etunimet_korjattu += Replace-Diacritics -Text $etunimi
        }

        if($lista1[$i].sukunimi.count -eq 1){
            $sukunimi = ($lista1[$i].sukunimi)
        }else{
            if($lista1[$i].sukunimi.count -eq 0){$sukunimi = ""}
            if($lista1[$i].sukunimi.count -gt 1){$sukunimi = $lista1[$i].sukunimi -join("")}
        }

        $sukunimi = Replace-Diacritics -Text $sukunimi
        
    if($lista1[$i].etunimi | select-string -pattern "-" -quiet){
        $yhdistelmat += rakenna -etunimet ($etunimet_viivalla -join("")) -sukunimi $sukunimi
        $yhdistelmat += rakenna -etunimet ($etunimet_viivalla) -sukunimi $sukunimi
    }
    
    
        $yhdistelmat += rakenna -etunimet $etunimet_korjattu -sukunimi $sukunimi


    





       

         
    return $yhdistelmat
}



#tekee varsinaisen analyysin loydetyista tuloksista
#palauttaa joko hyvintodennakoisesti oikean tilin tai "ei tuloksia"

function hakuanalyysi2{
    param($id)
    
    $verrattavat = verrattavatili2 -i $id
    $kohteet = paikallinen_adhaku -hakusanalista ($verrattavat)
    $tulokset = @()
    class tulokset{
       $verrattava
       $kohde
       $tulos

       [int]haetulos(){
        if($this.verrattava -eq $null -or $this.kohde -eq $null){return $null}else{return Get-LevenshteinDistance -source $this.verrattava -target $this.kohde}
       
       }
       



    }

    

    foreach($verrattava in $verrattavat){
      
        $tulos = [tulokset]::new()
        $tulos.verrattava = $verrattava

        



        foreach($kohde in $kohteet){
            $tulos.kohde = $kohde
            $tulos.tulos = $tulos.haetulos()
            if($tulos.tulos -eq 0){return $tulos}
             
        
                                }
           
            

            



    }
        
    
return "ei tuloksia"
    
}







#prosessoi saadut tulokset
#rakentaa tiedot listaan, jonka skripti lopuksi tekee
#prosessissa voi menna pitkaan, joten skripti ilmoittaa edistymisen

function prosessoi2{

    write-progress -Activity "Prosessoi" -Status "Aloittaa" -PercentComplete 0
    $tulos = @()
    for($i=0;$i-lt $lista0.count ;$i++){
        
       $haku = hakuanalyysi2 -i $i
       if($haku.kohde -eq "tyhja"){$tunnus = ""}else{$tunnus = $haku.kohde | where-object {$_.tulos -eq 0}}
       if($haku.maara -eq "tyhja"){$maara = 0}else{$maara = $haku.kohde.count | select-object -Unique}
       
       
        $temp = [PSCustomObject]@{
           henkilo = $nimilista[$i]
           tunnus = ""
           
          

            
        }
        if($haku -ne "ei tuloksia"){$temp.tunnus = $haku.kohde}
        $tulos += $temp
        write-progress -Activity ("Prosessoi:" + ($i/$lista1.length * 100)) -Status $nimilista[$i] -PercentComplete ($i/$lista0.length * 100) 

    }
    write-progress -Activity "Prosessoi" -Status "valmis" -PercentComplete 100 -Completed 
    return $tulos

}
#$adtunnukset = prosessoi2


#yhdistaa tiedot studenta listasta kerattyihin tietoihin.
#eli yhdistaa tilin ja puhelinnumeron

function yhdista{
    
    $tulos = @()
    for($i=0;$i -lt $lista1.count;$i++){
        
        $yhdista = [PSCustomObject]@{
            id = $i
            nimi = $nimilista[$i]
            adnimi = $adtunnukset[$i].tunnus
            puhelinnumero = $lista1[$i].puhelinnumero
        }
        $yhdista.puhelinnumero ="AAA"+ $yhdista.puhelinnumero.ToString()
        $tulos += $yhdista
    }   
return $tulos
}


$yhdistetty = yhdista

#vie tiedot tulokset.csv tiedostoon. 
$yhdistetty | Export-Csv -Path "C:\temp\tulokset.csv" -Force -NoTypeInformation -Encoding utf8
