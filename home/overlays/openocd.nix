self: super: {
  openocd-git = super.stdenv.mkDerivation rec {
    name = "openocd-git+${version}";
    version = "ded67990";

    src = super.fetchgit {
      url = "https://repo.or.cz/openocd.git";
      rev = version;
      sha256 = "1mmf8348xwddjzcvhjy5ndiadgfk9xsmxm2s6zvn7vdf36wmh9m4";
      leaveDotGit = true;
    };

    buildInputs = with super; [
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
  };
}