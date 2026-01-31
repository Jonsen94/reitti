{
  postgres,
  postgresPackages,
  postgresImageName,
  postgresImageTag,
  pkgs,
}:
let
  description = "Postgis with h3";
  lang = "en_US.tf8";
  pgdata = "/var/lib/postgresql";
  initH3Script = pkgs.writeText "init-h3.sql" ''
    CREATE EXTENSION IF NOT EXISTS h3;
    CREATE EXTENSION IF NOT EXISTS h3_postgis CASCADE;
  '';
in
{
  postgresImage = pkgs.dockerTools.buildLayeredImage {
    name = postgresImageName;
    tag = postgresImageTag;

    # TODO: arch configurable? change final image tags and digest?
    fromImage = pkgs.dockerTools.pullImage {
      imageName = "postgis/postgis";
      imageDigest = "sha256:1cd5da788ab0deddabefb607a51fcfcbcaf6ebc44ab917452ed9f8a529fc8e24";
      sha256 = "sha256-lPeLgAJgg4WefxR0ds/96JK/0IiTIfWDF24m21mptic=";
      finalImageName = "postgis/postgis";
      finalImageTag = "latest";
      os = "linux";
      arch = "amd64";
    };
    contents = [
      postgresPackages.h3-pg
    ];

    # TODO: Many paths contain hardcoded version numbers, enhance?
    # TODO: change init script number
    enableFakechroot = true;
    fakeRootCommands = ''
      mkdir -p /usr/share/postgresql/18/extension /docker-entrypoint-initdb.d/ /usr/lib/postgresql/18/lib
      cp ${initH3Script} /docker-entrypoint-initdb.d/01-init-h3.sql
      cp -rs ${postgresPackages.h3-pg}/share/postgresql/extension/. /usr/share/postgresql/18/extension/
      cp -rs ${postgresPackages.h3-pg}/lib/. /usr/lib/postgresql/18/lib/
    '';

    config = {
      User = "postgres";
      ExposedPorts = {
        "5432/tcp" = { };
      };
      Cmd = [
        "postgres"
      ];
      StopSignal = "SIGINT";
      Volumes = {
        "${pgdata}" = { };
      };
      Entrypoint = [ "/usr/local/bin/docker-entrypoint.sh" ];
      Labels = {
        "maintainer" = "dedicatedcode"; # TODO: change?!
        "org.opencontainers.image.source" = "https://github.com/dedicatedcode/reitti"; # TODO: change
        "org.opencontainers.image.description" = description; # TODO: change
      };
    };
  };
}
