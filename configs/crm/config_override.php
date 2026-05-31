<?php
/*
 * Local overrides loaded by config.php if present.
 * Keep this file in infra configs, not in application git repo.
 */

$maxMailboxes = getenv('CRM_MAX_MAILBOXES');
$max_mailboxes = ($maxMailboxes === false || $maxMailboxes === '') ? 3 : (int) $maxMailboxes;
