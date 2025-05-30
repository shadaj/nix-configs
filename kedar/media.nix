{ config, pkgs, secrets, ...}:
{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        security = "user";

        "workgroup" = "WORKGROUP";
        "server string" = "kedar";
        "netbios name" = "kedar";
        "hosts allow" = "192.168.0.0/16 fe80::/10 100.64.0.0/10 localhost";
        "guest account" = "nobody";
        "map to guest" = "bad user";

        "use sendfile" = "yes";

        "printcap name" = "/dev/null";
        "load printers" = "no";
        "printing" = "bsd";

        "vfs objects" = "catia fruit streams_xattr";
        "fruit:metadata" = "stream";
      };

      media = {
        path = "/swamp/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      games = {
        path = "/tank/games";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      honeymelon-cache = {
        path = "/home/shadaj/.honeymelon";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      "Time Machine (kedar)" = {
        path = "/swamp/time-machine";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "fruit:resource" = "xattr";
      };
    };
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;

    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };

    extraServiceFiles = {
      tm = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>9</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <port>9</port>
            <txt-record>dk0=adVN=Time Machine (kedar),adVF=0x82</txt-record>
            <txt-record>sys=adVF=0x100</txt-record>
          </service>
        </service-group>
      '';
    };
  };
}
