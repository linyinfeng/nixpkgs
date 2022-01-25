{ lib, ... }:
{
  config.result = lib.mkAfter [ "after1" "after2" ];
}
