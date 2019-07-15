# Returns an attribute set defining user-level environment variables.
#
# home.nix turns this into a file that will be sourced on login.

{ pkgs }: rec {
  SETENV   = "1";  # indicate that this file was sourced

  KDEWM    = "i3";

  EDITOR   = "nvim";
  VISUAL   = "${EDITOR}";
  TERMINAL = "termite";

  MOZ_USE_XINPUT2 = "1";  # enable proper touchpad scrolling in firefox

  XDG_DOWNLOAD_DIR = ~/downloads;
  XDG_PICTURES_DIR = ~/share/pictures;
  XDG_DESKTOP_DIR  = ~/.;  # prevent ~/Desktop from being created automatically

  WEECHAT_HOME     = ~/.config/weechat;
  LESSHISTFILE     = "-";

  # add C compiler runtime libs to LD path to fix rust-lld
  LD_LIBRARY_PATH  = "${pkgs.stdenv.cc.cc.lib}/lib64:$LD_LIBRARY_PATH";
}
