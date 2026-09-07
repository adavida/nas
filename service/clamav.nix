{
  config,
  vars,
  ...
}:
{
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
    daemon.settings = {
      LocalSocket = vars.clamav_socket;
      LogVerbose = true;
      LogTime = true;
      LogClean = true;
    };
  };
}
