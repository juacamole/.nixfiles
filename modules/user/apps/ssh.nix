{ pkgs, config, ... }: {

programs.ssh = {
    enable = true;
    matchBlocks."*".addKeysToAgent = "yes";
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "${config.home.homeDirectory}/.ssh/juacamole-git";
      identitiesOnly = true;
    };
  };

  services.ssh-agent.enable = true;
}
