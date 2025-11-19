self: { config, lib, pkgs, ... }: let
  cfg = config.services.tre-showcontrol;
in with lib; {
  options.services.tre-showcontrol = {
    enable = mkEnableOption  "Shut down system if a certain IP does not respond to pings anymore";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.system}.default;
      defaultText = literalExpression "pkgs.tre-showcontrol";
      description = "package to use";
    };

  };

  config = let
    #treOpts = "--socketPath ${cfg.socket-path} --debounce ${builtins.toString cfg.debounce}";
  in mkIf cfg.enable {
    users.users.poweroff-user = {
      isSystemUser = true;
      group = "poweroff-user";
    };

    users.groups.poweroff-user = {};

    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.login1.power-off" &&
            subject.user == "poweroff-user") {
          return polkit.Result.YES;
        }
      });
    '';
    
    systemd.services.tre-showcontrol = {
      description = "Shut down system if a certain IP does not respond to pings anymore";
      after = [ 
        "tre-track-station.service"
      ];
      requires = [ "tre-track-station.service"];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.bash}/bin/bash -c '${cfg.package}/bin/tre-showcontrol --monitorIP=$(${pkgs.jq}/bin/jq -r \\'.\"show-control-ip\"\\' < /etc/tre-station/content.json)'";
        Restart = "always";
        WorkingDirectory = "/tmp";
        StandardOutput = "journal";
        StandardError = "journal";
        #ProtectSystem = "strict";
        
        User = "poweroff-user";
        ReadPaths = [ 
          "/etc/tre-station"
        ];
        Environment = [
          "DEBUG=monitor"
          "DEBUG_HIDE_DATE=1"
        ];
      };
    };
  };
}
