{ config, pkgs, secrets, ... }:

let
  ciSecrets = import secrets.ci;
in {
  imports = [ ];

  virtualisation.oci-containers.containers.drone-server = {
    image = "drone/drone:2";
    environment = {
      DRONE_GITHUB_CLIENT_ID = ciSecrets.client-id;
      DRONE_GITHUB_CLIENT_SECRET = ciSecrets.client-secret;
      DRONE_RPC_SECRET = ciSecrets.rpc-secret;
      DRONE_SERVER_HOST = ciSecrets.host;
      DRONE_SERVER_PORT = ":3001";
      DRONE_SERVER_PROTO = "http";
      DRONE_USER_CREATE = "username:shadaj,admin:true";
    };

    volumes = [ "/home/ci/drone-data:/data" ];

    extraOptions = [ "--network=host" ];
  };

  virtualisation.oci-containers.containers.drone-runner = {
    image = "drone/drone-runner-docker:1";
    environment = {
      DRONE_RPC_PROTO = "http";
      DRONE_RPC_HOST = "localhost:3001";
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
    cmd = [ "smee-client" "-u" ciSecrets.smee-url "-t" "http://localhost:3001/hook" ];
    extraOptions = [ "--init" "--network=host" ];
  };
}
