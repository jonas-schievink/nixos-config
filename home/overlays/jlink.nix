# Packages the J-Link Software and Documentation pack
self: super: {
  jlink = let
    version = "6.54a";
    sha256 = "1zksyvqvv1x7qh97rdb4n340bs7hg6hqb0d9r88xwmymq8gy3250";

    version-squashed = builtins.replaceStrings ["."] [""] version;

    # Check for new versions at:
    # https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack
    url = "https://www.segger.com/downloads/jlink/JLink_Linux_V${version-squashed}_x86_64.tgz";

    runtimeDeps = [ super.libudev ];
  in super.stdenv.mkDerivation {
    name = "jlink-${version}";
    inherit version;

    # Custom fetchurl-inspired src derivation that... "obtains" the sources
    src = super.runCommand (baseNameOf (toString url)) {
      buildInputs = [ super.curl ];
      outputHashMode = "flat";
      outputHashAlgo = "sha256";
      outputHash = sha256;
    } ''
      curl -k -d 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software' '${url}' -o "$out"
    '';

    buildInputs = with super; [
      autoPatchelfHook
      stdenv.cc.cc.lib
      qt5.qtbase
      xorg.libXcursor
      xorg.libXrandr
      ncurses5
    ];

    # TODO libjlinkarm.so.6 dlopens libudev.so.1/0, but doesn't get its RPATH set correctly
    # (because autoPatchelfHook only does that for executables)
    runtimeDependencies = runtimeDeps;
    runtimeRPath = super.lib.makeLibraryPath runtimeDeps;
    runtimeRPathTargets = [ "libjlinkarm.so.6" ];
    dontAutoPatchelf = 1;

    buildPhase = ":"; # nothing to build
    installPhase = ''
      mkdir -p $out/bin
      cp -R * $out/bin
    '';
    postFixup = ''
      autoPatchelf $out/*

      for target in $runtimeRPathTargets; do
        rpathOld=$(patchelf --print-rpath "$out/bin/$target")
        rpathNew="$rpathOld:$runtimeRPath"
        echo "Updating RPATH of $target"
        echo "  OLD: $rpathOld"
        echo "  NEW: $rpathNew"
        patchelf --set-rpath "$rpathNew" "$out/bin/$target"
      done
    '';
  };
}
