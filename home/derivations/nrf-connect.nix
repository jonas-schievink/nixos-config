{ fetchurl
, appimageTools
, autoPatchelfHook
, lib
, jlink

, pango
, cairo
, glib
, nss
, gdk-pixbuf
, gtk3
, atk
, dbus
, xorg
, expat
, libuuid
, alsaLib
}:

appimageTools.wrapType2 {
  name = "nrf-connect";
  src = fetchurl {
    url = "https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-Connect-for-Desktop/3-2-0/nrfconnect320x8664.AppImage";
    sha256 =  "1wdmjhp25mfiiaz2wxcdjyqaxxzzlpwhh0q1i31paymmlgf0bazp";
  };
  extraPkgs = pkgs: with pkgs; [
    nss
    dbus
    pango cairo glib gdk-pixbuf gtk3 atk
    at-spi2-core at-spi2-atk cups
    libuuid alsaLib expat nspr libcanberra jlink
  ] ++ (with pkgs.xorg; [
    libxcb libXcursor libXext libX11 libXcomposite libXrender libXdamage libXfixes libXi
    libXtst libXrandr
  ]);
}
