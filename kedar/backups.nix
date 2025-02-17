{ config, pkgs, unstable, secrets, ...}:

let
  backupSecrets = import secrets.backup;
in {
  services.restic.backups.home = {
    package = pkgs.restic;
    paths = [ "/home" ];

    repository = "s3:s3.us-west-000.backblazeb2.com/kedar-restic/home";
    initialize = true;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--max-unused 5%"
      "--compression max"
      "-o s3.connections=16"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [
      "--compression max"
      "-o s3.connections=16"
      "--verbose"
    ];

    timerConfig = {
      OnCalendar = "*-*-* 01:00:00";
    };

    environmentFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  services.restic.backups.media = {
    package = pkgs.restic;
    paths = [ "/swamp/media" ];
    exclude = [ "/swamp/media/*/icloud" "/swamp/media/shared-icloud" "/swamp/media/honeymelon" "/swamp/media/nsa320s/video/HomeVideos" ];

    repository = "s3:s3.us-west-000.backblazeb2.com/kedar-restic/media";
    initialize = true;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--max-unused 5%"
      "--compression max"
      "-o s3.connections=16"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [
      "--compression max"
      "-o s3.connections=16"
      "--verbose"
    ];

    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
    };

    environmentFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  systemd.services.rclone-time-machine = {
    description = "rclone time machine";
    restartIfChanged = false;
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      MemoryMax = "8G";
      Environment = [
        "GOMEMLIMT=8GiB"
        "GOGC=20"
      ];
      ExecStartPre = [
        "systemctl stop samba-smbd.service"
      ];
      ExecStart = [
        "${pkgs.rclone}/bin/rclone sync -P --fast-list --update --use-server-modtime --b2-hard-delete --b2-upload-cutoff 16M --b2-chunk-size 16M /swamp/time-machine :b2:kedar-restic/time-machine-rclone"
        "${pkgs.rclone}/bin/rclone cleanup -P :b2:kedar-restic/time-machine-rclone"
      ];
      ExecStopPost = [
        "systemctl start samba-smbd.service"
      ];
      User = "root";
      RuntimeDirectory = "rclone-time-machine";
      CacheDirectory = "rclone-time-machine";
      CacheDirectoryMode = "0700";
      PrivateTmp = true;
      EnvironmentFile = backupSecrets.s3CredentialsFile;
    };
  };

  systemd.timers.rclone-time-machine = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      Unit = "rclone-time-machine.service";
      OnCalendar = "*-*-* 03:00:00";
    };
  };
}
