_: {
  den.aspects.agent-secrets = {
    includes = [ ];

    nixos = {
      services.onepassword-secrets.secrets.openrouterAgentApiKey = {
        reference = "op://Infrastructure/openrouter-agent/credential";
        owner = "root";
        group = "root";
        mode = "0400";
        services = [ "zeroclaw" ];
      };
    };
  };
}
