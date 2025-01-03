{
  description = "Work nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Setup: https://github.com/zhaofengli/nix-homebrew/blob/main/README.md
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    tap-aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    tap-oktadeveloper = {
      url = "github:oktadeveloper/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, tap-aerospace, tap-oktadeveloper, ... }:
    let
      configuration = { pkgs, config, ... }: {
        nixpkgs.config.allowUnfree = true;
        homebrew = {
          enable = true;

          brews = [
            "bitwarden-cli"
            # "gh"
            # "git"
            # "gnu-sed"
            # "go@1.22"
            # "gopass"
            # "jq"
            # "kubectx"
            # "lastpass-cli"
            "mas"
            "oh-my-posh"
            "p7zip"
            # "paperkey"
            # "pinentry-mac"
            # "pipx"
            # "pyenv-virtualenv"
            # "python@3.10"
            "sevenzip"
            # "swagger-codegen"
            # "terraform"
            # "tree"
          ];

          casks = [
            "adobe-acrobat-reader"
            "aerospace"
            "alt-tab"
            # "amazon-chime"
            # "amazon-workspaces"
            "aws-vault"
            # "aws-vpn-client"
            "devpod"
            # "elgato-stream-deck"
            # "font-cascadia-code-pl"
            # "font-cascadia-code"
            # "font-cascadia-mono-pl"
            # "font-cascadia-mono"
            # "font-jetbrains-mono-nerd-font"
            # "font-jetbrains-mono"
            "github"
            "google-cloud-sdk"
            "iterm2"
            "karabiner-elements"
            "keepassxc"
            "monitorcontrol"
            # "moom"
            # "obs"
            # "obsidian"
            "okta"
            "postman"
            "raycast"
            "rectangle"
            # "session-manager-plugin"
            "slack"
            # "stats"
            "todoist"
            # "utm"
            "visual-studio-code"
            # "warp"
            # "zoom"
          ];

          masApps = {
            # "Amazon Prime Video" = 545519333;
          };

          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = [
          pkgs.alacritty
          pkgs.ghostty
          pkgs.neovim
          pkgs.tmux
          pkgs.mkalias
          pkgs.obsidian
          pkgs.github-cli
          pkgs.chezmoi
          pkgs.aws-sso-cli
          pkgs.awscli2
          pkgs.azure-cli
          # pkgs.bitwarden-cli
          # pkgs.bitwarden-desktop
          pkgs.direnv # There are a few versions of direnv to review.
          pkgs.fzf
          pkgs.gopass
          # pkgs.oh-my-posh
          pkgs.gnused
          # pkgs.vscode
          # pkgs.vscode-fhs
          pkgs.nixpkgs-fmt
          pkgs.tree
          pkgs.jq
          pkgs.bat
        ];

        fonts.packages = [
          pkgs.nerd-fonts.jetbrains-mono
          # (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
        ];

        system.activationScripts.applications.text =
          let
            env = pkgs.buildEnv {
              name = "system-applications";
              paths = config.environment.systemPackages;
              pathsToLink = "/Applications";
            };
          in
          pkgs.lib.mkForce ''
            # Set up applications.
            echo "setting up /Applications..." >&2
            rm -rf /Applications/Nix\ Apps
            mkdir -p /Applications/Nix\ Apps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "Making alias $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
            done
          '';

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Enable alternative shell support in nix-darwin.
        programs.zsh.enable = true;
        # programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";
      };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Terrences-Virtual-Machine
      darwinConfigurations."baseline" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              # enableRosetta = true;

              # User owning the Homebrew prefix
              user = "terrence";

              autoMigrate = true;

              # Optional: Declarative tap management
              taps = {
                # Note: uncomment if mutableTaps=false;
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;

                # Note: this is the github path to a builders homebrew location.
                # ls -al /opt/homebrew/Library/Taps/nikitabobko
                "nikitabobko/homebrew-tap" = tap-aerospace;
                "oktadeveloper/homebrew-tap" = tap-oktadeveloper;
              };

              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              # Note: If you have existing brew installation, you can rename the Taps directory:
              # sudo mv /opt/homebrew/Library/Taps /opt/homebrew/Library/Taps.mutable
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
