{ config, pkgs, lib, ... }:

# FIXME: nice-to-have, currently stateful, or bug
# TODO:  regression from Arch setup
let
  color = import ./colors.nix { dark = true; };

  lockScreen = "${pkgs.i3lock-color}/bin/i3lock-color -c 000000";

  # DPI of primary screen. Not yet used everywhere it should be.
  dpi = 192;

  i3 = pkgs.i3-gaps;
in {
  imports = [
    ./modules/cli-base
    ./modules/notifyd
  ];

  # TODO: screenshot
  # FIXME: on boot/login: amixer -c0 sset 'Headphone Mic Boost' 10dB
  # (gets rid of white noise on headphone output)

  # FIXME: Popup when plugging in ext. display (or autorandr)

  # Ensure keyboard layout is inherited from OS config
  home.keyboard = {
    layout = null;
    model = null;
    variant = null;
  };

  fonts.fontconfig.enable = true;

  services.syncthing.enable = true;

  services.unclutter = {
    enable = true;
    threshold = 3;
    timeout = 3;
  };

  services.random-background = {
    enable = true;
    imageDirectory = toString ~/share/pictures/bgs;
  };

  services.network-manager-applet.enable = true;
  services.pasystray.enable = true;
  services.blueman-applet.enable = true;
  services.lorri.enable = true;

  # configurable programs:

  programs.home-manager.enable = true;  # make home-manager install and manage itself
  manual.html.enable = true;            # install the HTML home-manager manual

  programs.lesspipe.enable = true;

  programs.ssh.enable = true;
  programs.ssh.hashKnownHosts = true;

  programs.texlive = {
    enable = true;
    extraPackages = texlive: { inherit (texlive) scheme-medium dinbrief; };
  };

  programs.termite = {
    enable = true;
    allowBold = true;
    audibleBell = false;
    cursorBlink = "off";
    scrollbackLines = 10000;

    backgroundColor = "#${color.background}";
    foregroundColor = "#${color.foreground}";
    colorsExtra = let
      # create config lines like "colorN = #aabbcc"
      lines = pkgs.lib.lists.imap0 (i: color: "color${toString i} = #${color}") color.colors;
    in
      builtins.concatStringsSep "\n" lines;
  };

  # FF extensions aren't currently packaged in Nix/home-manager, but they can
  # be synced automatically.
  programs.firefox = {
    enable = true;

    profiles.default = {
      userChrome = ''
        @-moz-document url("chrome://browser/content/browser.xhtml") {
          /* Hide the tab bar */
          #TabsToolbar {
            visibility: collapse !important;
            margin-bottom: 21px !important;
          }

          /* Hide the Vertical Tabs title bar */
          #sidebar-box[sidebarcommand="verticaltabsreloaded_go-dev_de-sidebar-action"] #sidebar-header {
            visibility: collapse !important;
          }
        }
      '';
    };
  };

  programs.zathura = {
    enable = true;
    options = {
      guioptions = "sv";                 # enables vertical scroll bar (default: s)
      selection-clipboard = "clipboard"; # copy to Ctrl+V clipboard, not middle mouse button clipboard
      smooth-scroll = true;              # smooth scrolling when using touchpad
    };
    extraConfig = ''
      map <A-Left> jumplist backward  # <Alt+Left>  pos before last navigation
      map <A-Right> jumplist forward  # <Alt+Right> pos after next navigation
    '';
  };

  # The screen locker needs `xsession.enable = true`
  services.screen-locker.enable = true;
  services.screen-locker.lockCmd = "${lockScreen}";

  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable = true;
    package = i3;
    config = let
      mod = "Mod4";  # Mod4 = windows key
      launcherCmd = "rofi -show drun -dpi ${toString dpi}";
      terminal = "${pkgs.termite}/bin/termite";

      # Creates an i3 color config.
      # border: the window border
      # indicator: When the container is set to V/H, one of the edges is this color
      mkColor = {
        border,
        indicator ? color.foreground,
        background ? color.background,
        foreground ? color.foreground,
      }: {
        background = "#${background}";
        childBorder = "#${border}";
        indicator = "#${indicator}";
        text = "#${foreground}";
        border = "#${border}";
      };

      mkBarColor = {
        background ? color.background,
        border ? color.darkGray,
        text ? color.foreground,
      }: {
        text = "#${text}";
        background = "#${background}";
        border = "#${border}";
      };

    in {
      modifier = mod;
      gaps = {
        inner = 5;
        outer = 5;
        smartBorders = "on";
        smartGaps = true;
      };
      floating.border = 4;  # FIXME should depend on pixel density
      floating.criteria = [
        { class = "plasmashell"; }
        { class = "plasma-desktop"; }
      ];
      focus.newWindow = "focus";  # FIXME should be reset to smart when urgency shows up in bar
      keybindings = lib.mkOptionDefault {
        "${mod}+Return" = ''exec "${terminal}"'';
        "${mod}+d" = ''exec "${launcherCmd}"'';

        "${mod}+l" = ''exec "${lockScreen}"'';

        # resizing
        "${mod}+Ctrl+Left"  = "resize shrink width  5 px or 5 ppt";
        "${mod}+Ctrl+Right" = "resize grow   width  5 px or 5 ppt";
        "${mod}+Ctrl+Down"  = "resize grow   height 5 px or 5 ppt";
        "${mod}+Ctrl+Up"    = "resize shrink height 5 px or 5 ppt";

        # additional 10th workspace
        "${mod}+0" = "workspace 10";
        "${mod}+Shift+0" = "move container to workspace 10";

        # default i3 binding not in home-manager?
        "${mod}+a" = "focus parent";

        "XF86MonBrightnessUp" = "exec ${pkgs.acpilight}/bin/xbacklight -inc 5 intel_backlight";
        "XF86MonBrightnessDown" = "exec ${pkgs.acpilight}/bin/xbacklight -dec 5 intel_backlight";

        "XF86AudioRaiseVolume" = "exec ${pkgs.pulseaudio-ctl}/bin/pulseaudio-ctl up 2";
        "XF86AudioLowerVolume" = "exec ${pkgs.pulseaudio-ctl}/bin/pulseaudio-ctl down 2";
        "XF86AudioMute" = "exec ${pkgs.pulseaudio-ctl}/bin/pulseaudio-ctl mute";
      };
      window.commands = [
        # kill the desktop window containing the wallpaper (i3 tries to tile it)
        # this is a bug in Plasma or i3 (can't Plasma use the root window?)
        {
          criteria = { title = "Desktop — Plasma"; };
          command = "kill";
        }
      ];
      modes = {};  # disable resize mode

      colors = {
        focused = mkColor {
          border = color.blue;
          indicator = color.yellow;
          background = color.foreground;
          foreground = color.background;
        };
        focusedInactive = mkColor { border = color.darkGray; };
        unfocused = mkColor { border = color.black; };
        urgent = mkColor { border = color.red; };
      };

      bars = [
        {
          position = "top";

          colors = {
            background = "#${color.background}";
            focusedWorkspace = mkBarColor { text = color.background; background = color.foreground; };
            inactiveWorkspace = mkBarColor { text = color.foreground; background = color.background; };
          };

          fonts = [ "FontAwesome 9" "Noto Mono for Powerline 9" ];

          statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3/status.toml";
        }
      ];
    };

    extraConfig = ''
      exec --no-startup-id ${i3}/bin/i3-msg workspace 1
      exec --no-startup-id ${pkgs.xorg.xsetroot}/bin/xsetroot -solid black
    '';
  };

  home.file.".config/i3/status.toml" = {
    onChange = "${i3}/bin/i3 restart";
    text = builtins.readFile ./i3status-rs.toml;
  };

  programs.rofi = {
    enable = true;

    cycle = true;
    font = "Monospace 9";
    scrollbar = true;
    lines = 20;
    location = "top";

    # Generate rofi theme (which is pseudo-CSS with a `.rasi` extension, apparently) from the global
    # color config.
    theme = let
      theme = ''
        /******************************************************************************
        * ROFI Color theme based on solarized_alternate by Rasmus Steinke
        ******************************************************************************/

        // `*` denotes the "global properties" section, which specifies default properties. Unlike
        // in CSS, this will not apply to every single element, it is closer to `html` instead.
        * {
            background-color: #${color.background};
            border-color:     #${color.foregroundAlt};
            text-color:       #${color.foreground};
        }

        window {
            border:           0px 3px solid 3px solid;
            border-color:     #${color.yellow};
            padding:          5;
        }
        message {
            border:       1px dash 0px 0px;
            padding:      1px;
        }
        listview {
            fixed-height: 0;
            border:       2px dash 0px 0px;
            spacing:      2px;
            scrollbar:    true;
            padding:      2px 0px 0px;
        }
        element {
            border:  0;
            padding: 1px;
        }

        // Highlight urgent windows
        element.urgent {
            text-color:       #${color.red};
        }

        // Slightly highlight focused windows
        element.active {
            text-color:       #${color.white};
        }

        // Every second row gets a slightly different bg color
        element.alternate {
            background-color: #${color.backgroundAlt};
        }

        // The selected element is highlighted via background
        element.selected {
            background-color: #${color.blue};
        }

        scrollbar {
            width:        4px;
            border:       0;
            handle-width: 8px;
            handle-color: #${color.foreground};
            padding:      0;
        }
        mode-switcher {
            border:       2px dash 0px 0px ;
        }
        inputbar {
            spacing:    0;
            padding:    1px;
        }
        case-indicator {
            spacing:    0;
        }
        entry {
            spacing:    0;
        }
        inputbar {
            children:   [ textbox-prompt,entry,case-indicator ];
        }
        textbox-prompt {
            expand:     false;
            str:        ">";
            margin:     0em 0.3em 0.1em 0em ;
        }
      '';
    in
      builtins.toFile "rofi-theme-generated.rasi" theme;
  };

  # Install additional user packages that don't have their own options.
  # These are actually defined in the `packages` file, so load them and look them up.
  # This approach solves several problems:
  # - Package installation with `nix-env` introduces state
  # - Derivation Names vs. Attribute Names inconsistencies (why do pkgs even have 2 names?)
  # - While `nix-env -iA` allows using the attribute name, `nix-env -eA` doesn't and can not be
  #   implemented, so we're stuck with derivation names when uninstalling something
  # - Opening an editor to edit `configuration.nix`/`home.nix` every time I want to (un)install a
  #   package is annoying (and I still have to run `nixos-rebuild switch` or `home-manager switch`
  #   afterwards)
  #
  # Now, package installation can be a trivial script that does:
  #   `echo PKG >> packages && home-manager switch`
  # And apart from this file, no state is needed - just check it into your config repo.
  home.packages = with builtins; let
    # Given a set and a list of attribute names, recursively look them up in `set`.
    #   `lookup pkgs ["xorg" "xdpyinfo"]` is equivalent to `pkgs.xorg.xdpyinfo`
    lookup   = set: names: foldl' (s: n: getAttr n s) set names;

    # Split `s` on every occurrence of `m`
    #   `split "A" "baAzA"` evaluates to `["ba" "z" ""]`
    split    = m: s: filter (isString) (builtins.split m s);

    content  = readFile ./packages;
    pkgstrs  = filter (s: s != "") (split "\n+" content);  # attribute paths to install
    pkgpaths = map (split "\\.") pkgstrs;
  in map (lookup pkgs) pkgpaths;

  home.extraOutputsToInstall = [ "doc" "info" "devdoc" ];

  home.file.".cargo/config".text = ''
    [install]
    root = "${toString ~/.local}"
  '';

  home.file.".config/mpv/mpv.conf".text = ''
    hwdec=vaapi
    vo=gpu
    hwdec-codecs=all
  '';

  home.file.".gdbinit".text = ''
    add-auto-load-safe-path /home/jonas/dev
  '';

  home.sessionVariables = rec {
    PATH = "/home/$USER/.local/bin:$PATH";

    EDITOR   = "nvim";
    VISUAL   = "${EDITOR}";
    TERMINAL = "termite";

    # set the man pager to `less` manually, since some systems don't use one by default
    MANPAGER = "${pkgs.less}/bin/less";

    XDG_DOWNLOAD_DIR = ~/downloads;
    XDG_PICTURES_DIR = ~/share/pictures;
    XDG_DESKTOP_DIR  = ~/.;  # prevent ~/Desktop from being created automatically

    WEECHAT_HOME     = ~/.config/weechat;
    LESSHISTFILE     = "-";

    MOZ_USE_XINPUT2 = "1";
  };

  home.file.".local/share/applications/reboot.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Reboot
      Exec="${pkgs.systemd}/bin/systemctl" reboot
      Comment=Reboots the System
    '';
  };
  home.file.".local/share/applications/poweroff.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Power Off
      Exec="${pkgs.systemd}/bin/systemctl" poweroff
      Comment=Shuts down the System
    '';
  };
}
