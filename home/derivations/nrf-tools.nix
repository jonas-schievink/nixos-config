{
  stdenv,
  fetchurl,

  autoPatchelfHook,
  buildFHSUserEnv,
  buildEnv,

  libudev,
  jlink,
}:

let
  version = "10.5.0";
  url = "https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/nRFCommandLineTools1050Linuxamd64tar.gz";
  sha256 = "1vyyb6fxfanf72pb06bc442hlk579xrvwcspakdf84zwlhw1sy97";

  src = fetchurl {
    inherit url sha256;
    name = "nrf-tools-src.tar.gz";
  };

  versionUnderscore = builtins.replaceStrings ["."] ["_"] version;
  targetFile = "./nRF-Command-Line-Tools_${versionUnderscore}_Linux-amd64.tar.gz";
  unpackPhase = ''
    set -o errexit
    mkdir src
    cd src
    echo "pulling out ${targetFile}"
    tar -xf "$src" "${targetFile}"
    tar -xvf "${targetFile}"
    rm "${targetFile}"
  '';

  # Simple: No dependencies besides libc stuff.
  mergehex = stdenv.mkDerivation {
    name = "mergehex-${version}";
    inherit version src unpackPhase;

    buildInputs = [ autoPatchelfHook ];

    installPhase = ''
      set -o errexit

      mkdir -p "$out/bin"
      cp mergehex/mergehex "$out/bin"
    '';
  };

  # This uses absolute hardcoded path to dlopen() the J-Link libs. Put it in jail.
  nrfjprog-raw = stdenv.mkDerivation {
    name = "nrf-tools-raw-${version}";
    inherit version src unpackPhase;

    buildInputs = [ libudev autoPatchelfHook ];

    installPhase = ''
      set -o errexit
      mkdir -p $out/{bin,lib,opt/nrfjprog}

      cp nrfjprog/nrfjprog nrfjprog/*.so nrfjprog/*.ini "$out/opt/nrfjprog"

      ln -s ../opt/nrfjprog/nrfjprog "$out/bin/nrfjprog"

      for library in nrfjprog/*.so; do
        ln -s "../opt/$library" "$out/lib"
      done
    '';
  };
  nrfjprog = buildFHSUserEnv {
    name = "nrfjprog";

    # We don't use the `pkgs` passed here since we also need them below. I don't even know why
    # they're passed here.
    targetPkgs = _: [
      nrfjprog-raw jlink
    ];

    extraBuildCommands = ''
      mkdir "$out/opt"
      ln -s "${jlink}/opt/SEGGER" "$out/opt/SEGGER"
    '';

    runScript = "nrfjprog";
  };
in
  buildEnv {
    name = "nrf-tools";
    paths = [
      mergehex nrfjprog
    ];
  }
