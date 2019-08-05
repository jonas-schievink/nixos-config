# Packages the J-Link Software and Documentation pack
self: super: {
  jlink = let
    version = "6.48a";
    sha256 = "0m24iwyw98yv99xza92bgsmjh12irqfv93g1phpcsxgq4gs0i5r6";

    version-squashed = builtins.replaceStrings ["."] [""] version;
    url = "https://www.segger.com/downloads/jlink/JLink_Linux_V${version-squashed}_x86_64.tgz";

    runtimeDeps = [ super.libudev ];
  in super.stdenv.mkDerivation {
    name = "jlink-${version}";
    inherit version;

    # Custom fetchurl-inspired src derivation that... "obtains" the sources
    src = super.stdenv.mkDerivation rec {
      name = baseNameOf (toString url);
      buildInputs = [ super.curl ];

      builder = builtins.toFile "builder.sh" ''
        source $stdenv/setup

        curl -k -d 'accept_license_agreement=accepted&submit=Download+software' '${url}' -o "$out"
      '';

      outputHashMode = "flat";
      outputHashAlgo = "sha256";
      outputHash = sha256;
    };

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
