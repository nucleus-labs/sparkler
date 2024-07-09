{ config, lib, ... }:

let
  cfg = config.services.sparkler;
in
{
  options.services.sparkler = {
    enable = lib.mkEnableOption "Enable declarative detached container management";
    containers = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Container configurations";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = lib.mapAttrs' (name: container: {
      "sparkler-${name}" = {
        description = "Dynamic container '${name}'";
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.systemd}/bin/systemd-nspawn --machine=${name} ${lib.concatMapStrings (opt: "--${opt.key}=${opt.value} ") container.options}";
          KillMode = "mixed";
          Type = "notify";
        };
      };
    }) cfg.containers;
  };
}