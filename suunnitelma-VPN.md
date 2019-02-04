`Pilvitegnologiat`
`ICT4TN024`


# Projektityösuunnitelma 

* ***Jarno Wermundsen***
* ***Miika Zitting***





















					
# Projektin tehtävä
Projektin tehtävänä on luoda VPN-palvelua pilvessä. Palvelimen hallinta Azuressa.

# Projektin tulostavoitteet
Projektin tulostavoitteina ovat:
- Toimiva VPN-palvelu
- selitettynä VPN palvelujen teoriaa ja käsitteitä
- VPN-yhteys, joka toimii mobiililaitteella ja tietokoneella
- Toistettavissa oleva projekti raportointi



# Projektin oppimistavoitteet 
Perehtyä VPN tekniikoihin ja palvelun tarjoamiseen. Tutustua palvelun tarjoamiseen ja hallintaan pilvipohjaisesti.

# Projektin rajaus 
Projektin piiriin ei kuulu palvelun markkionointi tai tuotteistaminen. Projektissa käytettäviä sovelluksia emme tee itse.



# Projektin riskit ja niihin varautuminen 
Projektin riskit on kartoittettu alla olevaan taulukkoon.

*) 3 = pieni, 2 = kohtuullinen, 1 = suuri/huomattava.

| Riski | Todennäköisyys | Seuraus- vaikutus | Syyt | Syiden ennaltaehkäisy | Seurauksiin varautuminen |
| ---	 | ---	 | ---	 | ---	 | ---	 | ---	 |
| Avainhenkilö jättää projektin | 3 | 1 | Henkilökohtaiset syyt, muut opinnot, hyvä työtarjous, kuolema, muu vakava vammautuminen | Mielekkäiden työkokonaisuuksien takaaminen, nykyaikaiset välineet työlle, sitoutuminen opintojen jatkamiseen | Projektin tehtävän ja tulosten määrittely ja jako |
| Projektin tehtävä jää muun työn jalkoihin | 2 | 2 | Projektikulttuuri heikko, töiden priorisointi epäonnistunut | Keskittyminen projektin tehtävään: n. 8-10t/vko lukujärjestykseen merkittyä työaikaa, säännölliset projekti palaverit | Päätös projektin keston, tavoitteen muuttamiseksi |
| Perehtyminen ja osaaminen ei riitä | 1 | 3 | Huono materiaali, riittämätön ohjaus, täysin odottamaton ongelma | Hyvä perehtyminen ja töiden sunnittelu | Sovellusten vaihtaminen, pilvipalvelun tarjoajan vaihtaminen, yhteydenotto opettajiin ja/tai asiantuntijoihin.
| Kustannusten nousu | 2 | 1 | Ei ymmärretä Azuren hinnoittelua | Luottokortin numeroa ei annettu palveluun | Vaihtoehtoinen palvelu Azurelle, kustannusten jakaminen |

## Projektiryhmä 
Projekti tehdään ryhmätyönä ryhmässä, johon kuuluvat 
- Miika Zitting 
- Jarno Wermundsen. 


## Projektin ympäristö 
Projekti toteutetaan alustavasti Microsoftin Azure alustaa käytättäen. Palvelin toimii Ubuntu 18.04 käyttöjärjestelmää käytäen. Palvelimen tekniset ominaisuudet ovat vastaavanlaiset:
- 1 prosessoriydin (VCPUCore)
- 2GB Keskusmuisti (RAM)
- 30GB SSD

## Käytettävät teknologiat, menetelmät ja työkalut 
Projektissa VPN-palvelimella liikkuvan datan VPN tunnelointiin käytetään StrongSwan IPSec ohjelmistoa, sekä IKEv2 protokollaa. 
Palvelimen etähallintaan Windowsilla käytetään PuTTy:a ja linuxilla suoraa terminaali SSH-yhteyttä.
Projektin raportointi tehdään markdwonilla ja raportin jakaminen GitHub palvelua käyttäen. Lopullinen palautettava raportti kopioidaan markdownilla kirjoitetusta tekstistä Word dokumenttiin noudattamaan Haaga-Helian raportointiohjetta.
Mobiililaitteilla käytämme Strongswan applikaatiota VPN yhteyden luomiseen palvelimellemme.

## Projektin vaiheistus, aikataulu ja työmäärät

Projekti alkaa 28.01.2019 ja päättyy 15.05.2019. 
Käytettävissä oleva työmäärä on 8-12 tuntia/viikko.

Työmäärät ja tehtävät vaihtelevat projektin vaiheen mukaan. Viikon alussa asetamme tavoitteen joka tulisi viikon aikana saavuttaa. Työmäärät jaetaan tasaisesti projektin tekijöiden kesken, omat erikoisosaamisalueet huomioon ottaen.

Projektin alussa keskitymme tutustumaan VPN protokolliin ja erilaisten valmiiden kaupallisten palveluiden käyttämien tekniikoiden tutkimiseen. Azure vaatii tutustumista ennen palvelimen luontia ja käyttöönottoa, jotta pystymme projektin edetessä hallinnan Azuren kautta tarvittaessa hoitamaan. Kun tekniikat ja järjestelmät tuntuvat olevan hallussa, aloitamme projektin työvaiheen.

Työvaiheessa keskitymme palvelimen konfigurointiin, sekä StrongSwanin ja IKEv2 ohjelmistojen toimintaan. 

Testausvaiheessa olemme saaneet palvelimen jo toimintakuntoon ja erilaisia laitteita käyttöen testaamme palvelumme käyttöä. Palvelun tulisi olla käytettävissä tietokoneilla, Android laitteilla, sekä IOS laitteilla. 


## Dokumentinhallinta
Dokumenttien hallintaan käytämme GitHub palvelua, johon lisäämme kaikki raporttimme, sekä mahdollisesti käytettävät koodit. GitHub palvelussa meillä on jo luotuna Pilviteknologiat repository, johon molemmilla projektiin osallistuvilla on muokkaus/julkaisu oikeudet. 

Käytämme virallisena raportointikielenä Englantia, sillä tahdomme käyttää dokumenttejamme mahdollisissa portfolioissamme jatkossa.

Linkki GitHubiin :
https://github.com/JarnoWer/Pilviteknologiat
