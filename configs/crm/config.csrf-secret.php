<?php
$secret = getenv('CRM_CSRF_SECRET');
if ($secret === false || $secret === '') {
    $secret = 'change-this-csrf-secret';
}
