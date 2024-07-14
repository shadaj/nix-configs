{ config, pkgs, unstable, secrets, ...}:

let
  backupSecrets = import secrets.backup;
in {
  services.restic.backups.home = {
    package = unstable.restic;
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
    package = unstable.restic;
    paths = [ "/swamp/media" ];
    exclude = [ "/swamp/media/*/icloud" "/swamp/media/shared-icloud" ];

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

  services.restic.backups.time-machine = {
    package = unstable.restic;
    paths = [ "/swamp/time-machine" ];

    repository = "s3:s3.us-west-000.backblazeb2.com/kedar-restic/time-machine";
    initialize = true;

    pruneOpts = [
      "--keep-last 1"
      "--max-unused 5%"
      "-o s3.connections=16"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [
      "-o s3.connections=16"
      "--verbose"
    ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
    };

    environmentFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  services.restic.backups.vaultwarden = {
    package = unstable.restic;
    paths = [ "/var/lib/bitwarden_rs" ];

    repository = "s3:s3.us-west-000.backblazeb2.com/kedar-restic/vaultwarden";
    initialize = true;

    pruneOpts = [
      "--keep-last 1"
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
      OnCalendar = "*-*-* 00:00:00";
    };

    environmentFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };
}
