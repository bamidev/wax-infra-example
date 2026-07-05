{ ... }: ''
  set -ex

  TENANT=$1

  incus launch base $1-prod0
  incus exec $1-rproxy -- nixos-rebuild switch --flake /etc/nixos#odoo-prod
''
