<?php

/*********************************************************************************
 * The contents of this file are subject to the SugarCRM Public License Version 1.1.2
 * ("License"); You may not use this file except in compliance with the
 * License. You may obtain a copy of the License at http://www.sugarcrm.com/SPL
 * Software distributed under the License is distributed on an  "AS IS"  basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 ********************************************************************************/

if (!function_exists('crm_env')) {
  function crm_env($name, $default = '')
  {
    $value = getenv($name);
    return ($value === false || $value === '') ? $default : $value;
  }
}

// Adjust error_reporting favourable to deployment.
version_compare(PHP_VERSION, '5.5.0') <= 0 ? error_reporting(E_WARNING & ~E_NOTICE & ~E_DEPRECATED & E_ERROR) : error_reporting(E_WARNING & ~E_NOTICE & ~E_DEPRECATED  & E_ERROR & ~E_STRICT); // PRODUCTION
//ini_set('display_errors','on'); version_compare(PHP_VERSION, '5.5.0') <= 0 ? error_reporting(E_WARNING & ~E_NOTICE & ~E_DEPRECATED) : error_reporting(E_ALL & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT);   // DEBUGGING
//ini_set('display_errors','on'); error_reporting(E_ALL); // STRICT DEVELOPMENT

include('vtigerversion.php');

ini_set('memory_limit', '512M');
ini_set('session.gc_maxlifetime', '86400');

$CALENDAR_DISPLAY = 'true';
$WORLD_CLOCK_DISPLAY = 'true';
$CALCULATOR_DISPLAY = 'true';
$CHAT_DISPLAY = 'true';
$USE_RTE = 'true';

$HELPDESK_SUPPORT_EMAIL_ID = crm_env('CRM_HELPDESK_EMAIL', 'support@example.local');
$HELPDESK_SUPPORT_NAME = crm_env('CRM_HELPDESK_NAME', 'legacy-crm CRM Team');
$HELPDESK_SUPPORT_EMAIL_REPLY_ID = $HELPDESK_SUPPORT_EMAIL_ID;

$dbconfig['db_server'] = crm_env('CRM_DB_HOST', crm_env('MYSQL_CONTAINER', 'mysql'));
$dbPort = crm_env('CRM_DB_PORT', crm_env('MYSQL_PORT', '3306'));
$dbconfig['db_port'] = $dbPort === '' ? '' : (strpos($dbPort, ':') === 0 ? $dbPort : ':' . $dbPort);
$dbconfig['db_username'] = crm_env('CRM_DB_USER', crm_env('MYSQL_USER', 'crm'));
$dbconfig['db_password'] = crm_env('CRM_DB_PASSWORD', crm_env('MYSQL_PASSWORD', 'change-me'));
$dbconfig['db_name'] = crm_env('CRM_DB_NAME', crm_env('MYSQL_DATABASE', 'crm'));
$dbconfig['db_type'] = 'mysqli';
$dbconfig['db_status'] = 'true';
$dbconfig['db_hostname'] = $dbconfig['db_server'] . $dbconfig['db_port'];
$dbconfig['log_sql'] = false;

$dbconfigoption['persistent'] = true;
$dbconfigoption['autofree'] = false;
$dbconfigoption['debug'] = 0;
$dbconfigoption['seqname_format'] = '%s_seq';
$dbconfigoption['portability'] = 0;
$dbconfigoption['ssl'] = false;

$host_name = $dbconfig['db_hostname'];

$holidays = crm_env('CRM_HOLIDAYS', '2.01,03.01,04.01,05.01,06.01,23.02,24.02,08.03,01.05,08.05,09.05,12.06,06.11');
$site_URL = crm_env('CRM_SITE_URL', 'http://localhost:8081/crm/');
$PORTAL_URL = crm_env('CRM_PORTAL_URL', $site_URL . 'customerportal');
$root_directory = crm_env('CRM_ROOT_DIRECTORY', '/var/www/html/example-crm.local/crm/');

$cache_dir = 'cache/';
$tmp_dir = 'cache/images/';
$import_dir = 'cache/import/';
$upload_dir = 'cache/upload/';

$upload_maxsize = 20971520;
$MINIMUM_CRON_FREQUENCY = 5;
$allow_exports = 'all';

$upload_badext = array('php', 'php3', 'php4', 'php5', 'pl', 'cgi', 'py', 'asp', 'cfm', 'js', 'vbs', 'html', 'htm', 'exe', 'bin', 'bat', 'sh', 'dll', 'phps', 'phtml', 'xhtml', 'rb', 'msi', 'jsp', 'shtml', 'sth', 'shtm');

$includeDirectory = $root_directory . 'include/';

$list_max_entries_per_page = '40';
$limitpage_navigation = '5';
$history_max_viewed = '5';
$default_module = 'Home';
$default_action = 'index';
$default_theme = 'softed';
$calculate_response_time = true;
$default_user_name = '';
$default_password = '';
$create_default_user = false;
$default_user_is_admin = false;
$disable_persistent_connections = false;

$currency_name = 'Russia, Rubles';
$default_charset = 'UTF-8';
$default_language = 'ru_ru';
$translation_string_prefix = false;
$cache_tab_perms = true;
$display_empty_home_blocks = false;
$disable_stats_tracking = false;
$application_unique_key = crm_env('CRM_APPLICATION_UNIQUE_KEY', 'change-this-application-key');

$listview_max_textlength = '40';
$php_max_execution_time = 0;
$default_timezone = crm_env('TZ', 'Europe/Moscow');

if (isset($default_timezone) && function_exists('date_default_timezone_set')) {
  @date_default_timezone_set($default_timezone);
}

$default_layout = 'v7';

include_once 'config.security.php';
