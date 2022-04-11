{ pkgs, lib, config, options, ... }:

with lib;

let
  cfg = config.services.godns;

  settingsFormat = pkgs.formats.json { };
  settingsFile = instanceCfg: settingsFormat.generate "godns.json" ({
    ip_url = "https://ip4.seeip.org";
    ipv6_url = "https://ip6.seeip.org";
    ip_type = "IPv4";
    interval = 300;
    resolver = "8.8.8.8";
  } // instanceCfg.settings);

  instanceOpt = {
    options = {
      settings = mkOption {
        type = types.submodule {
          freeformType = settingsFormat.type;
        };
        example = {
          provider = "Cloudflare";
          email = "example@example.com";
          login_token = "";
          domains = [{
            domain_name = "example.com";
            sub_domains = [ "www" ];
          }];
        };
        description = "Settings used by GoDNS.";
      };
      environmentFile = mkOption {
        type = with types; nullOr path;
        example = "/path/to/godns_secrets";
        default = null;
        description = ''
          EnvironmentFile as defined in <citerefentry><refentrytitle>systemd.exec</refentrytitle>
          <manvolnum>5</manvolnum></citerefentry>.
          Can be used to pass screts to the systemd service without adding them to the nix store.

          Environment variables in settings will be substitued.

          <programlisting>
            # snippet of godns instance config
            services.godns.instances.example = {
              environmentFile = "/path/to/godns_secrets";
              settings.login_token = "$LOGIN_TOKEN";
            };
          </programlisting>

          <programlisting>
            # content of the environment file /path/to/godns_secrets
            LOGIN_TOKEN=verysecretpassword
          </programlisting>
        '';
      };
      loadCredential = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "login_token_file:/path/to/my_secret_login_token" ];
        description = ''
          LoadCredential as defined in <citerefentry><refentrytitle>systemd.exec</refentrytitle>
          <manvolnum>5</manvolnum></citerefentry>.
          Can be used to pass secrets to the systemd service without adding them to the nix store.

          Environment variables in settings will be substitued. So $CREDENTIALS_DIRECTORY can be
          used in settings.

          <programlisting>
            # snippet of godns instance config
            services.godns.instances.example = {
              loadCredential = [
                "login_token_file:/path/to/my_secret_login_token"
              ];
              settings.login_token_file = "$CREDENTIALS_DIRECTORY/login_token_file";
            };
          </programlisting>
        '';
      };
    };
  };

  mkService = name: instanceCfg: nameValuePair
    "godns-${name}"
    {
      description = "GoDNS instance ${name}";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      script = ''
        config_file="$RUNTIME_DIRECTORY/config.json"
        touch "$config_file"
        chmod 600 "$config_file"
        ${pkgs.envsubst}/bin/envsubst \
          -i ${settingsFile instanceCfg} \
          -o "$config_file"
        ${cfg.package}/bin/godns -c "$config_file"
      '';

      serviceConfig = {
        DynamicUser = true;
        RuntimeDirectory = "godns-${name}";
        RuntimeDirectoryMode = 700;
        LoadCredential = instanceCfg.loadCredential;
        EnvironmentFile = mkIf (instanceCfg.environmentFile != null) instanceCfg.environmentFile;
        Restart = "on-failure";
      };
    };

in
{
  options = {
    services.godns = {
      package = mkOption {
        type = types.package;
        default = pkgs.godns;
        defaultText = literalExpression "pkgs.godns";
        description = "GoDNS package to use";
      };

      instances = mkOption {
        type = with types; attrsOf (submodule instanceOpt);
        default = { };
        description = "GoDNS instances";
      };
    };
  };

  config = mkIf (cfg.instances != { }) {
    systemd.services = mapAttrs' mkService cfg.instances;
  };
}
