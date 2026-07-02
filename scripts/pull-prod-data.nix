{ pkgs, ribbon }: with pkgs; ''
  set -ex
  PROD=$(cat /etc/production | head -n 1)
  PSQL="${postgresql}/bin/psql -v ON_ERROR_STOP=1"

  function cleanup() {
    ${postgresql}/bin/dropdb _odoo_imported
  }

  function sanitize() {
    $PSQL -c "UPDATE ir_cron SET active = FALSE"
    $PSQL -c "UPDATE ir_mail_server SET active = FALSE, smtp_host = NULL, smtp_pass = NULL"
    ${postgresql}/bin/psql -c "UPDATE fetchmail_server SET active = FALSE, server = NULL, password = NULL"
  }

  # Make and download dump from production
  ${openssh}/bin/ssh "$PROD" pg_dump -F c /tmp/db.pgcustom
  ${openssh}/bin/scp "$PROD":/tmp/db.pgcustom /tmp/imported_db.pgcustom

  # Import the database
  $PSQL -c "DROP DATABASE IF EXISTS _odoo_imported"
  ${postgresql}/bin/pg_restore -O -d _odoo_imported /tmp/imported_db.pgcustom

  # Sanitize database, but if anything fails, delete the unsanitized database to prevent sensitive
  # data remaining on disk.
  trap cleanup EXIT INT TERM
  sanitize
  if [ -f /etc/wax/sanitize-db.sql ]; then
    $PSQL < /etc/wax/sanitize-db.sql
  fi
  $PSQL -c "UPDATE ir_config_parameter SET value = '${ribbon}' WHERE key = 'ribbon.name'"
  trap - EXIT INT TERM

  $PSQL -c "DROP DATABASE IF EXISTS odoo"
  $PSQL -c "ALTER DATABASE _odoo_imported RENAME TO odoo"
''
