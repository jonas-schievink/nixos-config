{ config, pkgs, ... }:

{
  # PostgreSQL database for development.
  services.postgresql = {
    enable = true;
    # We trust anything connecting to localhost or via the Unix socket. This is clearly vulnerable
    # against DNS rebinding attacks, but since this is only a development database with test data
    # in it, this should not be a big risk.
    authentication = pkgs.lib.mkForce ''
      local all all              trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
  };
}
