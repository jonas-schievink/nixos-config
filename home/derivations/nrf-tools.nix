{
  stdenv,
  fetchurl,

  autoPatchelfHook,
  buildFHSUserEnv,
  buildEnv,

  libudev,
  libusb,
  jlink,
}:

let
  version = "10.12.1";
  url = "https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-12-1/nRFCommandLineTools10121Linuxamd64.tar.gz";
  sha256 = "1141myf8nn464i1iaw79q6xm2a1mdn3hmaygwxpz1dqxcgfmi5dr";

  src = fetchurl {
    inherit url sha256;
    name = "nrf-tools-src.tar.gz";
  };

  versionUnderscore = builtins.replaceStrings ["."] ["_"] version;
  targetFile = "./nRF-Command-Line-Tools_${versionUnderscore}.tar";
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

    buildInputs = [ libudev libusb autoPatchelfHook ];

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
