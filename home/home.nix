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
  # configure services (these are autostarted by systemd-user):

  # TODO: screenshot
  # TODO: on boot/login: amixer -c0 sset 'Headphone Mic Boost' 10dB
  # (gets rid of white noise on headphone output)

  # XXX KDE:
  # Display and Monitor
  # * Rendering backend: OpenGL 3.1
  # * Animation speed: Instant
  # Startup and Shutdown -> Desktop Session
  # * check "Start with an empty session"
  # * uncheck "Confirm logout"
  # Features:
  # * Popup when plugging in ext. display

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

  # custom systemd units/services/sockets/etc:

  systemd.user.sockets.lorri = {
    Unit = {
      Description = "lorri build daemon";
    };

    Socket = {
      ListenStream = "%t/lorri/daemon.socket";
    };

    Install = {
      WantedBy = [ "sockets.target" ];
    };
  };

  systemd.user.services.lorri = {
    Unit = {
      Description = "lorri build daemon";
      Documentation = "https://github.com/target/lorri";
      ConditionUser = "!@system";
      Requires = "lorri.socket";
      Wants = "lorri.socket";
      RefuseManualStart = true;
    };
    Service = {
      ExecStart = "${pkgs.lorri}/bin/lorri daemon";
      PrivateTmp = true;
      ProtectSystem = "strict";
      WorkingDirectory = "%h";
      Restart = "on-failure";
      # Lorri needs Nix in its PATH
      Environment = ''
        PATH=${pkgs.nix}/bin
        RUST_BACKTRACE=1
      '';
    };
  };


  # configurable programs:

  programs.home-manager.enable = true;  # make home-manager install and manage itself
  manual.html.enable = true;            # install the HTML home-manager manual

  programs.lesspipe.enable = true;

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

  programs.htop = {
    enable = true;
    hideUserlandThreads = true;
    highlightBaseName = true;
    shadowOtherUsers = true;
    showProgramPath = false;  # these get too long with Nix :)
    meters.left = [ "AllCPUs" ];
    meters.right = [ "Memory" "Swap" "Blank" "Tasks" "LoadAverage" "Battery" "Clock" ];
  };

  programs.bat.enable = true;

  # TODO: `man` completion is broken

  programs.fish = {
    enable = true;
    shellAbbrs = {
      ls = "exa";
      ll = "exa -lFbhgm";
      la = "exa -lFbhgma";
      tree = "exa --tree -lFbhgm";
      cat = "bat";
      gs = "git status";
      gd = "git diff";
      gl = "git log";
      gca = "git commit -a";
      gco = "git checkout";
      grc = "git rebase --continue";
      pull = "git pull";
      rusti = "evcxr";  # cargo install evcxr-repl
    };
    shellAliases = {
      less = "less -R";
      dmesg = "dmesg --color=always";
      cp = "cp --reflink=auto";
    };
    # The default direnv hook uses the `fish_prompt` event. The `fish_preexec`
    # event is better, since using Alt+Left/Right doesn't fire the prompt
    # event.
    # Ironically this also fires when the command is empty, so it's basically
    # a superset of `fish_prompt`.
    interactiveShellInit = ''
      function __direnv_export_eval --on-event fish_preexec;
        eval ("${pkgs.direnv}/bin/direnv" export fish);
      end
    '';
    shellInit = ''
      set fish_greeting  # disable greeting
      set fish_prompt_pwd_dir_length 0
    '';

    promptInit = builtins.readFile ./fish_prompt.fish;
  };

  # Enable direnv...
  programs.direnv.enable = true;
  # ...we have our own integration though
  programs.direnv.enableFishIntegration = false;

  # FF extensions aren't currently packaged in Nix/home-manager, but they can
  # be synced automatically.
  programs.firefox = {
    enable = true;

    profiles.default = {
      userChrome = ''
        @-moz-document url("chrome://browser/content/browser.xul") {
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

  programs.neovim = {
    enable = true;
    vimAlias = true;
    # to get syntax highlighting, the vimrc contents are in their own file
    extraConfig = builtins.readFile ./vimrc;
    plugins = with pkgs.vimPlugins; [
      vim-airline vim-nix vim-toml
    ];
  };

  programs.git = {
    enable = true;
    userName = "Jonas Schievink";
    userEmail = "jonasschievink@gmail.com";
    extraConfig = {
      push.default = "simple";
      push.followTags = true;  # push tags by default
      pull.rebase = true;      # rebase instead of merge on pull
      rebase.autostash = true; # autostash on rebase to simplify `git pull` workflow
      rerere.enabled = true;
    };
    ignores = [
      ".idea"
      "*.iml"
      "CMakeLists.txt.user"
      "*.swp"
      "*.swo"
      "*~"
      "*.autosave"
      ".vscode"
      "__pycache__/"

      # Avoid the "i use nix btw" starter pack
      ".envrc"
      "shell.nix"
    ];
    aliases = {
      squash-all = "!f(){ git reset $(git commit-tree HEAD^{tree} -m \"\${1:-A new start}\");};f";
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

  xsession.windowManager.i3 = {
    enable = true;
    package = i3;
    config = let
      mod = "Mod4";  # Mod4 = windows key
      launcherCmd = "rofi -combi-modi window,drun -show combi -modi combi -dpi ${toString dpi}";
      terminal = "${pkgs.termite}/bin/termite";

      # Creates an i3 color config.
      # border: the window border
      # indicator: When the container is set to V/H, one of the edges is this color
      mkColor = { border, indicator ? color.foreground }: {
        background = "#000000";
        childBorder = "#${border}";
        indicator = "#${indicator}";
        text = "#0000ff";
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
        focused = mkColor { border = color.blue; indicator = color.yellow; };
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

  # NixOS always puts ~/bin in every users $PATH, so use that for Cargo binaries
  # This will unfortunately also create `~/.crates.toml`
  home.file.".cargo/config".text = ''
    [install]
    root = "${toString ~/.}"
  '';

  home.file.".config/mpv/mpv.conf".text = ''
    hwdec=vaapi
    vo=gpu
    hwdec-codecs=all
  '';

  home.file.".gdbinit".text = ''
    add-auto-load-safe-path /home/jonas/dev
  '';

  # make KDE source the env var configuration on startup
  # yes, this is DE-specific even on X11 :(
  # using PAM means that NixOS will override many vars in /etc/profile
  # using home.sessionVariables means the vars are only available inside terminals
  home.file.".config/plasma-workspace/env/vars.sh" = {
    executable = true;
    text = "source $HOME/.setenv";
  };
  home.file.".xsessionrc" = {
    executable = true;
    text = "source $HOME/.setenv";
  };
  home.file.".xprofile" = {
    executable = true;
    text = "source $HOME/.setenv";
  };
  home.file.".profile" = {
    executable = true;
    text = "source $HOME/.setenv";
  };

  home.file.".setenv" = {
    executable = true;
    text = let
      prefix = "#!${pkgs.bash}/bin/bash";
      mkEnv = attrs: builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList
        (name: value: "export ${name}=${toString value}")
        attrs
      );
    in prefix + "\n\n" + mkEnv (import ./env.nix { inherit pkgs; });
  };
}
