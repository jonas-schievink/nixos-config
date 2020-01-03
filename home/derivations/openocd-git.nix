{
  stdenv,
  fetchgit,

  libtool,
  pkg-config,
  automake,
  autoconf,
  which,
  git,
  jimtcl,
  libusb,
  hidapi,
}:

# Builds OpenOCD from a git revision since they don't have an observable release schedule.

stdenv.mkDerivation rec {
  name = "openocd-git+${version}";
  version = "9f1529da";

  # Can't use fetchFromRepoOrCz because we need .git for the submodules
  src = fetchgit {
    url = "https://repo.or.cz/openocd.git";
    rev = version;
    sha256 = "0y45v41hdxlfzc4knbwwhldqx7hlzc5rjwqs3xp6yh2cqyyqp3s6";
    leaveDotGit = true;
  };

  buildInputs = [
    libtool pkg-config automake autoconf which git jimtcl libusb hidapi
  ];

  features = [
    "aice"
    "amtjtagaccel"
    "armjtagew"
    "at91rm9200"
    "bcm2835gpio"
    "buspirate"
    "cmsis-dap"
    "dummy"
    "ep93xx"
    "ftdi"
    "gw16012"
    "ioutil"
    "jlink"
    "jtag_vpi"
    "legacy-ft2232_libftdi"
    "oocd_trace"
    "opendous"
    "openjtag_ftdi"
    "osbdm"
    "parport"
    "presto_libftdi"
    "remote-bitbang"
    "rlink"
    "stlink"
    "sysfsgpio"
    "ti-icdi"
    "ulink"
    "usb-blaster-2"
    "usb_blaster_libftdi"
    "usbprog"
    "vsllink"
  ];

  preConfigure = ''
    echo "[Nix] Running ./bootstrap"
    ./bootstrap
  '';

  configureFlags = builtins.map (f: "--enable-${f}") features ++ ["--disable-werror"];
}
