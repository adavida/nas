{
  base_dn = "DC=nas-test,DC=local";
  base_host = "nas-test.local";
  ca = (builtins.readFile ./homeCA.crt);
  dns_ip = "192.168.1.254";
  ip = "100.85.202.52";
  photoprism_originals_path = "/data/ssd/photoprism-originals";
}
