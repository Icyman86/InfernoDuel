# Inferno Duel: Legends — Linux prototype v0.1.0

[Download de Linux-build](https://github.com/Icyman86/InfernoDuel/raw/refs/tags/v0.1.0/releases/v0.1.0/InfernoDuel-Linux-v0.1.tar.gz)

Pak het archief uit en start `PLAY.sh` in de map `InfernoDuel-Linux`.
Vereist Linux x86_64 en OpenGL 3.3. Godot hoeft niet apart geïnstalleerd te zijn.
Dit pakket bevat de volledige Godot-engine en is daardoor circa 88 MiB.

P1: A/D bewegen, W springen, S blokkeren, F/G/H/J aanvallen.
P2: pijltjes bewegen/springen/blokkeren, I/O/P/L aanvallen. Esc pauzeert.

SharkByte en Bullet zijn speelbare geometrische prototypes. De overige acht
fighters en definitieve animaties volgen later. Zie de README in de projectroot
en `docs/TEST_LOG.md` voor de uitgevoerde tests en resterende beperkingen.

Controleer het archief met `sha256sum -c SHA256SUMS` vanuit deze map.
Het buildbestand staat rechtstreeks in Git, omdat de Releases-API tijdens
publicatie niet bereikbaar was vanuit de cloudomgeving.
