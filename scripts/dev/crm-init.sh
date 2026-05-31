#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

IFS=' ' read -r -a COMPOSE_PARTS <<<"${COMPOSE:-docker compose}"
APACHE_SERVICE="${APACHE_SERVICE:-apache}"

env_value() {
  local key="$1"
  local env_file="${PROJECT_ROOT}/.env"
  if [[ ! -f "${env_file}" ]]; then
    return 1
  fi

  awk -F= -v k="${key}" '$1==k {print substr($0, index($0, "=")+1); exit}' "${env_file}" \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//'
}

if [[ -z "${APP_CODE_PATH:-}" ]]; then
  APP_CODE_PATH="$(env_value APP_CODE_PATH || true)"
fi
APP_CODE_PATH="${APP_CODE_PATH:-./html/example-crm.local}"

if [[ "${APP_CODE_PATH}" != /* ]]; then
  APP_CODE_PATH="${PROJECT_ROOT}/${APP_CODE_PATH#./}"
fi

CRM_ROOT="${APP_CODE_PATH}/crm"

run_compose() {
  "${COMPOSE_PARTS[@]}" "$@"
}

log() {
  echo "[crm-init] $*"
}

ensure_runtime_cache_connector() {
  local cache_dir="${CRM_ROOT}/includes/runtime/cache"
  local connector_file="${cache_dir}/Connector.php"
  local connectors_file="${cache_dir}/Connectors.php"

  mkdir -p "${cache_dir}"

  if [[ ! -f "${connector_file}" ]]; then
    cat >"${connector_file}" <<'PHP'
<?php
include_once dirname(__FILE__).'/Connectors.php';

class Vtiger_Cache_Connector {
	protected static $instance;
	protected $backend;

	private function __construct() {
		$this->backend = new Vtiger_RuntimeCache_Connector();
	}

	public static function getInstance() {
		if (!self::$instance) {
			self::$instance = new self();
		}
		return self::$instance;
	}

	public function get($ns, $key) {
		return $this->backend->get($ns, $key);
	}

	public function set($ns, $key, $value) {
		$this->backend->set($ns, $key, $value);
	}

	public function delete($ns, $key) {
		$this->backend->delete($ns, $key);
	}

	public function flush() {
		$this->backend->flush();
	}
}
PHP
    log "Created missing ${connector_file}"
  fi

  if [[ ! -f "${connectors_file}" ]]; then
    cat >"${connectors_file}" <<'PHP'
<?php
class Vtiger_RuntimeCache_Connector {
	protected static $store = array();

	protected function index($ns, $key) {
		return $ns . '::' . $key;
	}

	public function get($ns, $key) {
		$idx = $this->index($ns, $key);
		return array_key_exists($idx, self::$store) ? self::$store[$idx] : false;
	}

	public function set($ns, $key, $value) {
		self::$store[$this->index($ns, $key)] = $value;
	}

	public function delete($ns, $key) {
		unset(self::$store[$this->index($ns, $key)]);
	}

	public function flush() {
		self::$store = array();
	}
}
PHP
    log "Created missing ${connectors_file}"
  fi
}

ensure_user_privileges_dir() {
  local dir="${CRM_ROOT}/user_privileges"
  mkdir -p "${dir}"

  [[ -f "${dir}/index.html" ]] || printf '%s\n' '<html><body></body></html>' >"${dir}/index.html"
  [[ -f "${dir}/audit_trail.php" ]] || printf '%s\n' '<?php' >"${dir}/audit_trail.php"
  [[ -f "${dir}/default_module_view.php" ]] || printf '%s\n' '<?php' >"${dir}/default_module_view.php"
  [[ -f "${dir}/enable_backup.php" ]] || printf '%s\n' '<?php' >"${dir}/enable_backup.php"
}

rebuild_user_privileges() {
  if ! run_compose ps --services --status running | grep -qx "${APACHE_SERVICE}"; then
    log "Container ${APACHE_SERVICE} is not running, skip privileges rebuild"
    return 0
  fi

  run_compose exec -T --user www-data "${APACHE_SERVICE}" sh -lc '
    cd /var/www/html/example-crm.local/crm || exit 1
    php -d display_errors=0 -r "
      require_once \"config.inc.php\";
      require_once \"include/utils/UserInfoUtil.php\";
      global \$adb;
      if (!\$adb) {
        fwrite(STDERR, \"DB is not available\n\");
        exit(2);
      }
      \$check = \$adb->pquery(\"SHOW TABLES LIKE ?\", array(\"vtiger_users\"));
      if (!\$check || \$adb->num_rows(\$check) === 0) {
        echo \"SKIP_NO_IMPORTED_DB\n\";
        exit(0);
      }
      RecalculateSharingRules();
      echo \"PRIVILEGES_REBUILT\n\";
    "
  '
}

main() {
  if [[ ! -d "${CRM_ROOT}" ]]; then
    echo "[crm-init] CRM directory not found: ${CRM_ROOT}" >&2
    echo "[crm-init] Ensure APP_CODE_PATH points to directory that contains crm/" >&2
    exit 1
  fi

  ensure_runtime_cache_connector
  ensure_user_privileges_dir
  rebuild_user_privileges

  log "Done"
}

main "$@"
