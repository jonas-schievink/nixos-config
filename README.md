Adding a new machine's NixOS config:

```
$ mkdir machines/<name>
$ cp /etc/nixos/* machines/<name>
$ sudo ln -s <checkout>machines/<name>/configuration.nix /etc/nixos/configuration.nix
```

Restoring a machine's configuration:

```
$ sudo ln -s <checkout>/machines/<name>/configuration.nix /etc/nixos/configuration.nix
```

Linking the nixpkgs and home-manager config:

```
$ ln -s <checkout>/home ~/.config/nixpkgs
```

