#!/bin/bash

set -e
echo "Starting Entrypoint"
echo "Params $1  and $2"

if [ -v PASSWORD_FILE ]; then
    PASSWORD="$(<$PASSWORD_FILE)"
fi

# set the postgres database host, port, user and password according to the environment
# and pass them as arguments to the odoo process if not present in the config file
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC"; then
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d " " -f3 | sed 's/["\n\r]//g')
    fi
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

ADD_ARGS=()


if [[ "$SERVER_WIDE_MODULES" != "undefined" ]]; then
    #check_config "server_wide_modules" "$SERVER_WIDE_MODULES"
    ADD_ARGS+=("--load")
    ADD_ARGS+=("${SERVER_WIDE_MODULES}")
    
fi

TOINSTALL=''

if [[ "$ODOO_NATIVE_MODULES" != "undefined" ]]; then
    TOINSTALL+="$ODOO_NATIVE_MODULES"
fi

if [[ "$ODOO_EXTRA_MODULES" != "undefined" ]]; then
    if [[ -n "$TOINSTALL" ]]; then
        TOINSTALL="$TOINSTALL,"
    fi
    TOINSTALL+="$ODOO_EXTRA_MODULES"
fi

if [[ -n "$TOINSTALL" ]]; then
    ADD_ARGS+=("--init")
    ADD_ARGS+=("${TOINSTALL}")
fi

ODOO_ARGS= ("${DB_ARGS[@]}" "${ADD_ARGS[@]}")

echo "ODOO ARGUMENTS: ${ODOO_ARGS[@]}"

case "$1" in
-- | odoo)
    shift
    if [[ "$1" == "scaffold" ]]; then
        exec odoo "$@"
    else
        wait-for-psql.py ${DB_ARGS[@]} --timeout=30
        exec odoo "$@" "${ODOO_ARGS[@]}"
    fi
    ;;
-*)
    wait-for-psql.py ${DB_ARGS[@]} --timeout=30
    exec odoo "$@" "${ODOO_ARGS[@]}"
    ;;
*)
    exec "$@"
    ;;
esac

exit 1
