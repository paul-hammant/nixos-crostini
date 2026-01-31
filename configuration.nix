# Originally taken from:
# https://github.com/Misterio77/nix-starter-configs/blob/cd2634edb7742a5b4bbf6520a2403c22be7013c6/minimal/nixos/configuration.nix
# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  # inputs,
  # lib,
  # config,
  pkgs,
  ...
}:
{
  # Deploy CLAUDE.md for Claude Code context
  # Place in /etc/nixos (found when working there) and link to user home
  environment.etc."nixos/CLAUDE.md".source = ./CLAUDE.md;

  # Create ~/.claude/CLAUDE.md for paul (always checked by Claude Code)
  system.activationScripts.claudemd = ''
    mkdir -p /home/paul/.claude
    ln -sf /etc/nixos/CLAUDE.md /home/paul/.claude/CLAUDE.md
    chown -R paul:users /home/paul/.claude
  '';

  imports = [
    # You can import other NixOS modules here.
    # You can also split up your configuration and import pieces of it here:
    # ./users.nix
  ];

  # Enable flakes: https://nixos.wiki/wiki/Flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Allow unfree packages (required for claude-code)
  nixpkgs.config.allowUnfree = true;

  # Search for additional packages here: https://search.nixos.org/packages
  environment.systemPackages = with pkgs; [
    neovim
    git
    nodejs
    gemini-cli
    go
    ripgrep
    claude-code
  ];

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    paul = {
      isNormalUser = true;

      linger = true;
      extraGroups = [ "wheel" ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
