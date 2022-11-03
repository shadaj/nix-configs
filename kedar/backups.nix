{ config, pkgs, secrets, ...}:

let
  backupSecrets = import secrets.backup;
in {
  services.restic.backups.home = {
    paths = [ "/home" ];

    repository = "b2:kedar-restic:home";
    initialize = true;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--max-unused 5%"
      "--compression max"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [ "--compression max" "--verbose" ];

    timerConfig = {
      OnCalendar = "*-*-* 01:00:00";
    };

    s3CredentialsFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  services.restic.backups.media = {
    paths = [ "/swamp/media" ];

    repository = "b2:kedar-restic:media";
    initialize = true;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--max-unused 5%"
      "--compression max"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [ "--compression max" "--verbose" ];

    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
    };

    s3CredentialsFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  services.restic.backups.time-machine = {
    paths = [ "/swamp/time-machine" ];

    repository = "b2:kedar-restic:time-machine";
    initialize = true;

    pruneOpts = [
      "--keep-last 1"
      "--max-unused 5%"
      "--compression max"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [ "--compression max" "--verbose" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
    };

    s3CredentialsFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };
}
