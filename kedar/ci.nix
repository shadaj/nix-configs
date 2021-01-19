{ config, pkgs, ... }:

let
  secrets = import ./ci.secret.nix;
in {
  imports = [ ./ci-access.nix ];

  virtualisation.oci-containers.containers.drone-server = {
    image = "drone/drone:1.9";
    environment = {
      DRONE_GITHUB_CLIENT_ID = secrets.client-id;
      DRONE_GITHUB_CLIENT_SECRET = secrets.client-secret;
      DRONE_RPC_SECRET = secrets.rpc-secret;
      DRONE_SERVER_HOST = "kedar.local";
      DRONE_SERVER_PROTO = "http";
      DRONE_USER_CREATE = "username:shadaj,admin:true";
    };

    volumes = [ "/home/ci/drone-data:/data" ];

    extraOptions = [ "--network=host" ];
  };

  virtualisation.oci-containers.containers.drone-runner = {
    image = "drone/drone-runner-docker:1.4";
    environment = {
      DRONE_RPC_PROTO = "http";
      DRONE_RPC_HOST = "kedar";
      DRONE_RPC_SECRET = "abcd1234";
      DRONE_RUNNER_CAPACITY = "2";
      DRONE_RUNNER_NAME = "kedar-runner";
    };

    volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];

    extraOptions = [ "--network=host" ];
  };

  virtualisation.oci-containers.containers.smee = {
    image = "node:lts-alpine";
    entrypoint = "npx";
    cmd = [ "smee-client" "-u" secrets.smee-url "-t" "http://localhost:80/hook" ];
    extraOptions = [ "--init" "--network=host" ];
  };
}
