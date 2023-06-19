# powershell skriptit

Puhelinnumero.ps1
--esimerkki-tiedot.csv
-Skripti hakee active directory tilin käyttäen tietoja esimerkki-tiedot.csv tiedostosta. Esimerkki tiedot voi korvata oikeilla tiedoilla saman kaavan mukaan, eli nimi kohtaan nimi: sukunimi, etunimet ja puhelinnumero kohtaan
puhelinnumero.

-Skripti muuntaa myös puhelinnumeron +358 muotoon, jotta sitä voi käyttää azuressa.

-Lopuksi skripti yhdistää tiedot ja tekee niistä csv tiedoston. Yhdistetyissä tiedoissa näkyy henkilön nimi, löydetty active directory tili ja muokattu puhelinnumero.
-active directoryssä olevien tilien oletetaan olevan etunimi.sukunimi@jotain.fi tyylisesti. 
-skripti hakee tilit tekemällä kaikki mahdolliset yhdistelmät henkilön etunimistä ja sukunimestä, etsii niihin liittyvät ad tilit ja valitsee sen joka on lähimpänä henkilön nimeä. 
-jos skripti ei osaa korjata puhelinnumeroa +358 alkuiseksi, numero merkitään tekstillä ja alkuperäinen numero lisätään tekstin perään
-jos skripti ei löydä sopivaa ad tiliä, kohta jätetään tyhjäksi.

-skriptä voi kehittää antamaan enemmän tuloksia niille joista ei näytetä mitään, mutta virheen mahdollisuus nousee silloin ja se pitää ottaa huomioon tulosten näyttämisessä.
-skripti osaa korvata erikosimerkit

------------------------
tunnustenluonti.ps1

-tunnustenluonti skripti paikalliselle active directorylle
-skriptistä poistettu tietoja tietoturvasyistä ja se ei voi toimia ilman muokkauksia

  -manuaalinen moodi -> luo yksi tunnus manuaalisesti. skripti kysyy tarvittavat tiedot
  -massamoodi -> lisää haluamasi tiedot tilitiedot.txt tiedostoon, samaan tapaan kuin esimerkkitiedossa. Skripti käy sen läpi ja luo automaattisesti tunnukset tietojen perusteella.
  -hakumoodi -> tarkista onko joku tunnus olemassa ad:ssa 
  -varmistus -> skripti ei tee mitään pysyvää ilman varmistus komentoa, vahinkojen ehkäisemiseksi
  


