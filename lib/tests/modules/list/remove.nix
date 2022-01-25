{ lib, ... }:
{
  # will remove "before1" "default1"
  # will not remove "after1", because "after1" is added after this remove (order is bigger)
  config.result = lib.mkRemove 1000 [ "before1" "default1" "after1" ];
}
