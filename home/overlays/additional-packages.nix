self: super: let
  pkg = name: super.callPackage (../derivations + "/${name}.nix") {};
in {
  jlink = pkg "jlink";
  nrf-tools = pkg "nrf-tools";
  openocd-git = pkg "openocd-git";
}
