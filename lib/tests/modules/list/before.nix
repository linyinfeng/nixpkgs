{ lib, ... }:
{
  config.result = lib.mkBefore [ "before1" "before2" ];
}
