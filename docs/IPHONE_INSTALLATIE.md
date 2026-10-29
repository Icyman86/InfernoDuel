# Inferno Duel 0.9 op iPhone installeren zonder App Store

Dat kan met **AltStore Classic**, via een Windows-pc of Mac en je eigen Apple
Account. Geen jailbreak of betaald Apple Developer-abonnement nodig voor de
gratis methode. De app wordt op jouw computer voor jouw iPhone ondertekend.
Een `.ipa` alleen in Safari downloaden en openen installeert de app niet.
De Android-APK werkt niet op een iPhone.

## Welk bestand heb je nodig?

Open de [iPhone 0.9 release](https://github.com/Icyman86/InfernoDuel/releases/tag/v0.9.0-ios)
en download **InfernoDuel-iPhone-v0.9.0-unsigned.ipa** uit Assets.
Deze verschijnt uitsluitend nadat de automatische Mac-build is geslaagd.
Het woord `unsigned` hoort erbij: AltStore voegt jouw eigen ondertekening toe.
`Source code.zip` of een Xcode-project is geen installeerbare app.

De app is bedoeld voor **iOS 15 of nieuwer**, in landschap. iPad wordt ook
meegenomen in het exportprofiel. Je hebt voor installatie internet, een
USB-kabel, een Apple Account en een Windows-pc of Mac nodig. CPU-spel werkt
na installatie offline. Installatie en prestaties op een echte iPhone zijn
nog niet bevestigd; zie de buildstatus en testnotities in de repository.

## 1. AltStore Classic installeren

1. Download **AltServer** van [de officiële AltStore-website](https://altstore.io/).
   Kies **AltStore Classic**, niet AltStore PAL. PAL is geen algemene installer
   voor eigen IPA-bestanden en is voor deze route niet nodig.
2. Installeer AltServer op je computer en start het. Volg de actuele
   [Windows-handleiding](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows)
   of [Mac-handleiding](https://faq.altstore.io/altstore-classic/how-to-install-altstore-macos).
   Op Windows vraagt AltServer ook om Apple-onderdelen zoals iTunes/iCloud;
   gebruik de versies waarnaar de officiële handleiding verwijst.
3. Sluit je iPhone met USB aan, ontgrendel hem en bevestig **Vertrouw deze computer**.
   Controleer dat hij zichtbaar is in Finder/iTunes en zet synchronisatie via
   wifi aan als je later draadloos wilt vernieuwen.
4. Kies bij het AltServer-icoon **Install AltStore → jouw iPhone**. Meld je in
   AltServer aan met je eigen Apple Account en rond eventuele verificatie af.
   Deel je wachtwoord of verificatiecodes niet met mij of in GitHub.
5. Vertrouw zo nodig je ontwikkelaarsprofiel op de iPhone via
   **Instellingen → Algemeen → VPN en apparaatbeheer**. De precieze benaming
   hangt af van je iOS-versie.
6. Op **iOS 16 en nieuwer** zet je **Instellingen → Privacy en beveiliging →
   Ontwikkelaarsmodus** aan als iOS daarom vraagt. Herstart en bevestig.
   Verschijnt die optie nog niet, installeer AltStore eerst en kijk opnieuw.

## 2. Inferno Duel toevoegen

1. Download de bovenstaande `.ipa` op je iPhone naar Bestanden/iCloud Drive.
   Je kunt hem ook op de computer downloaden en naar Bestanden overzetten.
2. Houd AltServer op de computer actief. Verbind de iPhone met USB of zorg
   voor werkende wifi-synchronisatie op hetzelfde netwerk.
3. Open **AltStore → My Apps → +** en kies de `.ipa`.
4. AltStore ondertekent en installeert Inferno Duel. Wacht tot dit klaar is.
5. Open **Inferno Duel: Legends**, houd de iPhone horizontaal en kies
   **PLAY · TOUCH VS CPU**, of **CONNECT · SESSION CODE** voor lokaal netwerkspel.
6. Sta **Lokaal netwerk** toe als iOS daarom vraagt. Als je dit hebt geweigerd,
   wijzig je het bij **Instellingen → Privacy en beveiliging → Lokaal netwerk**.

## 3. Elke zeven dagen vernieuwen

Met een gratis Apple Account vervalt de ondertekening normaal na **zeven dagen**.
Open vóór die tijd **AltStore → My Apps → Refresh All**, met AltServer actief
en een bereikbare computer. AltStore kan ook automatisch vernieuwen als de
achtergrond- en netwerkvoorwaarden goed zijn; controleer zelf de resterende dagen.
Wifi-synchronisatie is handig, maar gebruik USB als draadloos vernieuwen niet lukt.

Apple beperkt gratis accounts normaal tot drie actieve sideload-apps, inclusief
AltStore, en beperkt het aantal App IDs. Heeft installatie een limietfout, bekijk
die melding in AltStore en de officiële uitleg. Na verlopen certificaten moet je
opnieuw vernieuwen/installeren via AltServer; een APK of webdownload lost dat niet op.
Een betaald Developer-account heeft andere limieten, maar is hiervoor niet verplicht.

## Sessies met een ander toestel

De game gebruikt dezelfde zes tekens en versie 0.9 als Android. Beide toestellen
moeten op dezelfde wifi zitten, zonder isolatie van gasten of clients. Op iPhone
wordt alleen in maximaal twee nabije private IPv4-/24-netwerken gezocht met
unicast; er is geen multicast-entitlement, publieke directory of relay nodig.
Grotere of afwijkende netwerkindelingen kunnen daardoor niet gevonden worden.

Met de bestaande Android V9-APK: laat bij voorkeur **Android CREATE SESSION** doen
en vul de code op de **iPhone** in. De oudere Android-lookup gebruikt broadcast;
een iPhone-host is daarmee nog niet op echte apparaten gevalideerd. iPhone-naar-
iPhone heeft de nieuwe unicast-lookup aan beide kanten. Geen van deze routes is
al met echte iPhones getest. Andere wifi-netwerken of 4G/5G worden niet door de
sessiecode overbrugd. CPU-spel heeft geen lokaal-netwerktoestemming nodig.

## Als er nog geen IPA bij de release staat

Bekijk [de iPhone-builds in GitHub Actions](https://github.com/Icyman86/InfernoDuel/actions/workflows/ios.yml).
Alleen een geslaagde Mac/Xcode-build kan een echte IPA produceren. De workflow
bouwt zonder Apple-wachtwoorden, certificaten of provisioningprofielen; AltStore
doet de uiteindelijke ondertekening op jouw computer. Een mislukte of niet gestarte
build is geen installeerbare release.

Een Mac met Xcode kan vanuit de broncode ook `python3 tools/setup_ios_ci.py` en
vervolgens, met de getoonde GODOT_BIN, `./tools/build_ios.sh` uitvoeren. Dat levert
dezelfde unsigned IPA op. Een geëxporteerd `.xcodeproj` kun je daarnaast in Xcode
openen, jouw eigen Personal Team kiezen bij Signing & Capabilities en rechtstreeks
op je aangesloten iPhone draaien. Vervang daarvoor de export-placeholder voor
het team door jouw echte team; `0000000000` is geen Apple-certificaat of account.

Officiële uitleg: [AltStore FAQ](https://faq.altstore.io/),
[Apple Ontwikkelaarsmodus](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device),
[Apple gratis en betaalde lidmaatschappen](https://developer.apple.com/support/compare-memberships/).
