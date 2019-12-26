# Packages the J-Link Software and Documentation pack

{
  curl,
  runCommand,
  lib,
  autoPatchelfHook,
  stdenv,

  qt4,
  libXcursor,
  libXrandr,
  ncurses5,
  libudev,
  libedit,
}:

let
  version = "6.54a";
  sha256 = "1zksyvqvv1x7qh97rdb4n340bs7hg6hqb0d9r88xwmymq8gy3250";

  version-squashed = builtins.replaceStrings ["."] [""] version;

  # Check for new versions at:
  # https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack
  url = "https://www.segger.com/downloads/jlink/JLink_Linux_V${version-squashed}_x86_64.tgz";

  # Dependencies opened via dlopen. These need manual RPATH entries.
  runtimeDependencies = [ libudev libedit ];
in stdenv.mkDerivation {
  name = "jlink-${version}";
  inherit version;

  # Custom fetchurl-inspired src derivation that... "obtains" the sources
  src = runCommand (baseNameOf (toString url)) {
    buildInputs = [ curl ];
    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = sha256;
  } ''
    curl -k -d 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software' '${url}' -o "$out"
  '';

  buildInputs = [
    autoPatchelfHook
    stdenv.cc.cc.lib
    qt4
    libXcursor
    libXrandr
    ncurses5
  ];

  # libjlinkarm.so.6 dlopens libudev.so.1/0, but doesn't get its RPATH set correctly
  # (because autoPatchelfHook only does that for executables). Do that manually.
  inherit runtimeDependencies;
  runtimeRPath = lib.makeLibraryPath runtimeDependencies;
  runtimeRPathTargets = [ "libjlinkarm.so.6" ];
  dontAutoPatchelf = 1;

  dontBuild = true;  # binary package, nothing to build

  # We install everything needed for functionality to "$out/opt/SEGGER/JLink" and then link
  # binaries/libraries to "$out/{bin,lib}". That way, the tools will find the libjlinkarm library.
  installPhase = ''
    mkdir -p $out/{bin,lib,opt/SEGGER/JLink}

    cp -P libjlink*.so* "$out/opt/SEGGER/JLink"
    cp -P J* "$out/opt/SEGGER/JLink"

    for binary in J*; do
      ln -s "../opt/SEGGER/JLink/$binary" "$out/bin/$binary"
    done

    for library in libjlink*.so*; do
      ln -s "../opt/SEGGER/JLink/$libary" "$out/lib/$library"
    done
  '';
  postFixup = ''
    autoPatchelf "$out/opt/SEGGER/JLink"

    echo "Patching libraries with dlopen()ed dependencies..."
    for target in $runtimeRPathTargets; do
      rpathOld=$(patchelf --print-rpath "$out/opt/SEGGER/JLink/$target")
      rpathNew="$rpathOld:$runtimeRPath"
      echo "Updating RPATH of $target"
      echo "  OLD: $rpathOld"
      echo "  NEW: $rpathNew"
      patchelf --set-rpath "$rpathNew" "$out/opt/SEGGER/JLink/$target"
    done
  '';
}
