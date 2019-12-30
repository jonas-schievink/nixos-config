{ config, lib, pkgs, ... }:

# Configures the shell and command line tools:
{
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

  # Put all CLI tools into the environment that are used by `abbr`s:

  home.packages = with pkgs; [
    exa evcxr git direnv
  ];

  programs.bat.enable = true;

  programs.htop = {
    enable = true;
    hideUserlandThreads = true;
    highlightBaseName = true;
    shadowOtherUsers = true;
    showProgramPath = false;  # these get too long with Nix :)
    meters.left = [ "AllCPUs" ];
    meters.right = [ "Memory" "Swap" "Blank" "Tasks" "LoadAverage" "Battery" "Clock" ];
  };

  # Enable direnv...
  programs.direnv.enable = true;
  # ...we have our own integration though
  programs.direnv.enableFishIntegration = false;

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
}
