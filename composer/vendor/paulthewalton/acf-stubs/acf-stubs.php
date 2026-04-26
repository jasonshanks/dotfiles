<?php
/**
 * ACF (Advanced Custom Fields) Function Stubs for Intelephense
 * These are common functions from the free version of ACF
 * @see https://www.advancedcustomfields.com/
 */

/**
 * Get a field value from the current post
 *
 * @param string $selector The field name or key
 * @param false|int $post_id The post ID. Defaults to current post
 * @param bool $format_value Whether to format the value
 * @return mixed
 */
function get_field($selector, $post_id = false, $format_value = true) {}

/**
 * Display a field value from the current post
 *
 * @param string $selector The field name or key
 * @param false|int $post_id The post ID
 * @param bool $format_value Whether to format the value
 * @return void
 */
function the_field($selector, $post_id = false, $format_value = true) {}

/**
 * Check if a field has a value
 *
 * @param string $selector The field name or key
 * @param false|int $post_id The post ID
 * @param bool $format_value Whether to format the value
 * @return bool
 */
function have_rows($selector, $post_id = false) {}

/**
 * Get a sub field value from a repeater/layout
 *
 * @param string $selector The field name or key
 * @param bool $format_value Whether to format the value
 * @return mixed
 */
function get_sub_field($selector, $format_value = true) {}

/**
 * Display a sub field value from a repeater/layout
 *
 * @param string $selector The field name or key
 * @param bool $format_value Whether to format the value
 * @return void
 */
function the_sub_field($selector, $format_value = true) {}

/**
 * Get a field object
 *
 * @param string $selector The field name or key
 * @param false|int $post_id The post ID
 * @param bool $format_value Whether to format the value
 * @return array|false
 */
function get_field_object($selector, $post_id = false, $format_value = true) {}

/**
 * Get an array of field names
 *
 * @param false|int $post_id The post ID
 * @param bool $hidden True to include hidden fields
 * @return array
 */
function get_field_keys($post_id = false, $hidden = false) {}

/**
 * Get an array of field groups
 *
 * @param array $args Arguments to filter by
 * @return array
 */
function acf_get_field_groups($args = array()) {}

/**
 * Get a field group
 *
 * @param int $post_id The post ID
 * @return array|false
 */
function acf_get_field_group($post_id) {}

/**
 * Render a field group form
 *
 * @param array $field_group The field group array
 * @param array $args Additional render args
 * @return void
 */
function acf_render_field_group($field_group, $args = array()) {}

/**
 * Render fields for a field group
 *
 * @param array $field_group The field group array
 * @return void
 */
function acf_render_fields($field_group) {}

/**
 * Validate a field group
 *
 * @param array $field_group The field group array
 * @return bool
 */
function acf_validate_field_group($field_group) {}

/**
 * Get a field
 *
 * @param string $selector The field name or key
 * @param false|int $post_id The post ID
 * @param bool $format_value Whether to format the value
 * @return array|false
 */
function acf_get_field($selector, $post_id = false, $format_value = true) {}

/**
 * Save a field
 *
 * @param int $post_id The post ID
 * @param array $field The field array
 * @return int|false
 */
function acf_update_field($field, $post_id) {}

/**
 * Delete a field
 *
 * @param string $selector The field name or key
 * @param int $post_id The post ID
 * @return bool
 */
function acf_delete_field($selector, $post_id) {}

/**
 * Duplicate a field
 *
 * @param string $selector The field name or key
 * @param int $post_id The post ID
 * @param int $new_post_id The new post ID
 * @return array|false
 */
function acf_duplicate_field($selector, $post_id, $new_post_id) {}

/**
 * Update a field value
 *
 * @param int $post_id The post ID
 * @param string $selector The field name or key
 * @param mixed $value The value to save
 * @return bool
 */
function update_field($selector, $value, $post_id) {}

/**
 * Delete a field value
 *
 * @param string $selector The field name or key
 * @param int $post_id The post ID
 * @return bool
 */
function delete_field($selector, $post_id) {}

/**
 * Reset the global row index
 *
 * @return void
 */
function reset_rows() {}

/**
 * Get the loop
 *
 * @return array
 */
function acf_get_loop($type = 'post') {}

/**
 * Set the loop
 *
 * @param array $loop The loop data
 * @param string $type The type
 * @return void
 */
function acf_set_loop($loop, $type = 'post') {}

/**
 * Remove the loop
 *
 * @param string $type The type
 * @return void
 */
function acf_unset_loop($type = 'post') {}

/**
 * Check if we are in a loop (for repeater/flexible content)
 *
 * @return bool
 */
function has_sub_field($selector, $post_id = false) {}

/**
 * Get a variation of a field
 *
 * @param string $selector The field name or key
 * @param int $post_id The post ID
 * @return mixed
 */
function get_field_variation($selector, $post_id = false) {}

/**
 * Get a value from a specific row in a repeater
 *
 * @param int $row The row number (1-based)
 * @param string $selector The field name
 * @param int $post_id The post ID
 * @param bool $format_value Whether to format
 * @return mixed
 */
function get_row($selector = '', $format_value = true) {}

/**
 * Get the row layout for flexible content
 *
 * @return string|false The layout name or false
 */
function get_row_layout() {}

/**
 * Start a row loop (flexible content)
 *
 * @param string $selector The field name
 * @param int|false $post_id The post ID
 * @return bool
 */
function the_row($selector = '', $post_id = false) {}

function get_row_index() {}

/**
 * Get row data
 *
 * @param array $args Arguments
 * @return array
 */
function get_row_data($args = array()) {}

/**
 * Has row data
 *
 * @param array $args Arguments
 * @return bool
 */
function has_row_data($args = array()) {}

/**
 * Get sub field object
 *
 * @return array|false
 */
function get_sub_field_object() {}

/**
 * Get post meta
 *
 * @param int $post_id The post ID
 * @param array $args Arguments
 * @return array
 */
function acf_get_post_meta($post_id, $args = array()) {}

/**
 * Get meta
 *
 * @param int $post_id The post ID
 * @param string $key The meta key
 * @param bool $single Whether to get single value
 * @return mixed
 */
function acf_get_meta($post_id = 0, $key = '', $single = false) {}

/**
 * Update post meta
 *
 * @param int $post_id The post ID
 * @param array $metas The meta data
 * @return bool
 */
function acf_update_post_meta($post_id, $metas) {}

/**
 * Delete post meta
 *
 * @param int $post_id The post ID
 * @param array $metas The meta data
 * @return bool
 */
function acf_delete_post_meta($post_id, $metas) {}

/**
 * Shortcode handler
 *
 * @param array $atts Shortcode attributes
 * @param string $content Shortcode content
 * @return string
 */
function acf_shortcode($atts, $content = '') {}

/**
 * Update shortcode
 *
 * @param array $atts Attributes
 * @param string $content Content
 * @return string
 */
function acf_shortcode_update($atts, $content = '') {}

/**
 * Form header
 *
 * @param array $args Form arguments
 * @return void
 */
function acf_form_head($args = array()) {}

/**
 * Form footer
 *
 * @return void
 */
function acf_form_footer() {}

/**
 * Do a form
 *
 * @param array $args Form arguments
 * @return void
 */
function acf_form($args = array()) {}

/**
 * Include a form
 *
 * @param array $args Form arguments
 * @return void
 */
function acf_include($args = array()) {}

/**
 * Get fields
 *
 * @param mixed $post_id Post ID or array of args
 * @param array $args Field arguments
 * @return array
 */
function acf_get_fields($post_id = false, $args = array()) {}

/**
 * Prepare field for export
 *
 * @param array $field The field array
 * @return array
 */
function acf_prepare_field($field) {}

/**
 * Prepare fields for export
 *
 * @param array $fields The fields array
 * @return array
 */
function acf_prepare_fields($fields) {}

/**
 * Render a field
 *
 * @param array $field The field array
 * @return void
 */
function acf_render_field($field) {}

/**
 * Render a field setting
 *
 * @param array $field The field array
 * @return void
 */
function acf_render_field_settings($field) {}

/**
 * Get fields for a specific post
 *
 * @param int $post_id The post ID
 * @param bool $format Whether to format value
 * @return array
 */
function acf_get_fields_for_input($post_id, $format = true) {}

/**
 * Get posted fields
 *
 * @return array
 */
function acf_get_posted_fields() {}

/**
 * Render a label
 *
 * @param array $field The field array
 * @return void
 */
function acf_render_field_label($field) {}

/**
 * Get field type classes
 *
 * @param array $field The field array
 * @return string
 */
function acf_get_field_type_class($type) {}

/**
 * Get field type label
 *
 * @param string $type The field type
 * @return string
 */
function acf_get_field_type_label($type) {}

/**
 * Validate field
 *
 * @param array $field The field array
 * @param string $input The input value
 * @return bool|string Error message or true
 */
function acf_validate_field($field, $input = '') {}

/**
 * Validate required field
 *
 * @param array $field The field array
 * @param mixed $value The value
 * @return bool
 */
function acf_validate_required_field($field, $value) {}

/**
 * Format field value
 *
 * @param mixed $value The value
 * @param array $field The field array
 * @param int $post_id The post ID
 * @return mixed
 */
function acf_format_value($value, $post_id, $field) {}

/**
 * Format post meta value
 *
 * @param mixed $value The value
 * @param int $post_id The post ID
 * @param array $field The field array
 * @return mixed
 */
function acf_format_value_for_api($value, $post_id, $field) {}

/**
 * Get the post id for the field
 *
 * @param array $field The field array
 * @return int
 */
function acf_get_valid_post_id($post_id = 0) {}

/**
 * Check if post id is a taxonomy
 *
 * @param int|string $post_id The post ID or taxonomy name
 * @return bool
 */
function acf_is_taxonomy($post_id) {}

/**
 * Get user role
 *
 * @param int $user_id The user ID
 * @return string
 */
function acf_get_user_role($user_id) {}

/**
 * Add user to wp_roles
 *
 * @param int $user_id The user ID
 * @param string $role The role
 * @return void
 */
function acf_add_user_to_role($user_id, $role) {}

/**
 * Remove user from wp_roles
 *
 * @param int $user_id The user ID
 * @return void
 */
function acf_remove_user_from_role($user_id) {}

/**
 * Get the current user role key
 *
 * @return string
 */
function acf_get_current_user_role_key() {}

/**
 * Get pretty user roles
 *
 * @return array
 */
function acf_get_pretty_user_roles() {}

/**
 * Get the current user role
 *
 * @return string
 */
function acf_get_current_user_role() {}

/**
 * Get the current user
 *
 * @return array|false
 */
function acf_get_current_user() {}

/**
 * Get current data
 *
 * @return array
 */
function acf_get_current_data() {}

/**
 * Is field hidden
 *
 * @param array $field The field array
 * @return bool
 */
function acf_is_field_hidden($field) {}

/**
 * Is field collapsed
 *
 * @param array $field The field array
 * @return bool
 */
function acf_is_field_collapsed($field) {}

/**
 * Show field
 *
 * @param array $field The field array
 * @return array
 */
function acf_show_field($field) {}

/**
 * Hide field
 *
 * @param array $field The field array
 * @return array
 */
function acf_hide_field($field) {}

/**
 * Collapse field
 *
 * @param array $field The field array
 * @return array
 */
function acf_collapse_field($field) {}

/**
 * Expose field
 *
 * @param array $field The field array
 * @return array
 */
function acf_expose_field($field) {}

/**
 * Get an array of available image sizes
 *
 * @return array
 */
function acf_get_image_sizes() {}

/**
 * Get thumbnail size
 *
 * @return array
 */
function acf_get_thumbnail_size() {}

/**
 * Get image id from url
 *
 * @param string $url The image URL
 * @return int|false
 */
function acf_get_image_id_from_url($url) {}

/**
 * Get attachment data
 *
 * @param int $id The attachment ID
 * @return array|false
 */
function acf_get_attachment($id) {}

/**
 * Get media dimensions
 *
 * @param int $id The attachment ID
 * @return array|false
 */
function acf_get_media_dimensions($id) {}

/**
 * Maybe resize image
 *
 * @param array $attachment The attachment array
 * @param array $args Resize arguments
 * @return array
 */
function acf_maybe_resize_image($attachment, $args = array()) {}

/**
 * Maybe crop image
 *
 * @param array $attachment The attachment array
 * @param array $args Crop arguments
 * @return array
 */
function acf_maybe_crop_image($attachment, $args = array()) {}

/**
 * Save an attachment
 *
 * @param array $attachment The attachment data
 * @param int $id The attachment ID (optional)
 * @return int
 */
function acf_save_attachment($attachment, $id = 0) {}

/**
 * Update an attachment
 *
 * @param int $id The attachment ID
 * @param array $attachment The attachment data
 * @return int|WP_Error
 */
function acf_update_attachment($id, $attachment) {}

/**
 * Delete an attachment
 *
 * @param int $id The attachment ID
 * @return bool
 */
function acf_delete_attachment($id) {}

/**
 * Update user meta
 *
 * @param int $user_id The user ID
 * @param array $metas Meta data to update
 * @return bool
 */
function acf_update_user_meta($user_id, $metas) {}

/**
 * Delete user meta
 *
 * @param int $user_id The user ID
 * @param array $metas Meta data to delete
 * @return bool
 */
function acf_delete_user_meta($user_id, $metas) {}

/**
 * Get user meta
 *
 * @param int $user_id The user ID
 * @param string $meta_key The meta key
 * @param bool $single Whether to get single value
 * @return mixed
 */
function acf_get_user_meta($user_id, $meta_key, $single = false) {}

/**
 * Get user role data
 *
 * @return array
 */
function acf_get_user_role_data() {}

/**
 * Get field group key
 *
 * @param string $key The field group key
 * @return string
 */
function acf_get_field_group_key($key) {}

/**
 * Generate a key
 *
 * @param string $prefix The prefix
 * @return string
 */
function acf_generate_key($prefix = 'field') {}

/**
 * Get an array of local post ids
 *
 * @param array $args Arguments
 * @return array
 */
function acf_local_post_ids($args = array()) {}

/**
 * Remove local post
 *
 * @param string $post_id The post ID
 * @return void
 */
function acf_remove_local_post($post_id) {}

/**
 * Update local post
 *
 * @param array $post The post array
 * @return void
 */
function acf_update_local_post($post) {}

/**
 * Get local posts
 *
 * @param array $args Arguments
 * @return array
 */
function acf_local_posts($args = array()) {}

/**
 * Get local post
 *
 * @param string $post_id The post ID
 * @return array|false
 */
function acf_get_local_post($post_id) {}

/**
 * Get local post types
 *
 * @return array
 */
function acf_local_post_types() {}

/**
 * Flush local post cache
 *
 * @return void
 */
function acf_flush_local_post_cache() {}

/**
 * Is local post
 *
 * @param string $post_id The post ID
 * @return bool
 */
function acf_is_local_post($post_id) {}

/**
 * Is local post new
 *
 * @param string $post_id The post ID
 * @return bool
 */
function acf_is_local_post_new($post_id) {}

/**
 * Get the stored json
 *
 * @param int $id The post ID
 * @return array
 */
function acf_get_stored_json($id) {}

/**
 * Prepare field group for export
 *
 * @param array $field_group The field group array
 * @return array
 */
function acf_prepare_field_group_for_export($field_group = array()) {}

/**
 * Prepare fields for export
 *
 * @param array $field_group The field group array
 * @return array
 */
function acf_prepare_fields_for_export($field_group = array()) {}

/**
 * Prepare field for import
 *
 * @param array $field The field array
 * @return array
 */
function acf_prepare_field_for_import($field = array()) {}

/**
 * Import field group
 *
 * @param array $field_group The field group array
 * @return void
 */
function acf_import_field_group($field_group) {}

/**
 * Import field
 *
 * @param array $field The field array
 * @return void
 */
function acf_import_field($field) {}

/**
 * Get tax terms
 *
 * @param int $post_id The post ID
 * @param array $args Arguments
 * @return array
 */
function acf_get_tax_terms($post_id = 0, $args = array()) {}

/**
 * Update tax terms
 *
 * @param int $post_id The post ID
 * @param array $taxonomies The taxonomies
 * @param array $terms The terms
 * @return void
 */
function acf_update_tax_terms($post_id, $taxonomies, $terms) {}

/**
 * Delete tax terms
 *
 * @param int $post_id The post ID
 * @param array $taxonomies The taxonomies
 * @return void
 */
function acf_delete_tax_terms($post_id, $taxonomies) {}

/**
 * Get post terms
 *
 * @param int $post_id The post ID
 * @param array $args Arguments
 * @return array
 */
function acf_get_post_terms($post_id = 0, $args = array()) {}

/**
 * Update post terms
 *
 * @param int $post_id The post ID
 * @param array $terms The terms
 * @return void
 */
function acf_update_post_terms($post_id, $terms) {}

/**
 * Delete post terms
 *
 * @param int $post_id The post ID
 * @return void
 */
function acf_delete_post_terms($post_id) {}

/**
 * Check if is in app
 *
 * @return bool
 */
function acf_is_app() {}

/**
 * Check if is admin
 *
 * @return bool
 */
function acf_is_admin() {}

/**
 * Check if is ajax
 *
 * @return bool
 */
function acf_is_ajax($action = '') {}

/**
 * Do action
 *
 * @param string $action The action
 * @param array $args The arguments
 * @return void
 */
function acf_do_action($action, $args = array()) {}

/**
 * Apply filters
 *
 * @param string $filter The filter
 * @param array $args The arguments
 * @return mixed
 */
function acf_apply_filters($filter, $args = array()) {}

/**
 * Add action
 *
 * @param string $hook The hook
 * @param callable $function The function
 * @param int $priority The priority
 * @return void
 */
function acf_add_action($hook, $function, $priority = 10) {}

/**
 * Add filter
 *
 * @param string $hook The hook
 * @param callable $function The function
 * @param int $priority The priority
 * @return void
 */
function acf_add_filter($hook, $function, $priority = 10) {}

/**
 * Remove action
 *
 * @param string $hook The hook
 * @param callable $function The function
 * @param int $priority The priority
 * @return void
 */
function acf_remove_action($hook, $function, $priority = 10) {}

/**
 * Remove filter
 *
 * @param string $hook The hook
 * @param callable $function The function
 * @param int $priority The priority
 * @return void
 */
function acf_remove_filter($hook, $function, $priority = 10) {}

/**
 * Get data
 *
 * @param string $selector The selector
 * @return mixed
 */
function acf_get_data($selector) {}

/**
 * Set data
 *
 * @param string $selector The selector
 * @param mixed $value The value
 * @return void
 */
function acf_set_data($selector, $value) {}

/**
 * Append data
 *
 * @param string $selector The selector
 * @param mixed $value The value
 * @return void
 */
function acf_append_data($selector, $value) {}

/**
 * Get user login
 *
 * @param int $user_id The user ID
 * @return string
 */
function acf_get_user_login($user_id) {}

/**
 * Get user email
 *
 * @param int $user_id The user ID
 * @return string|false
 */
function acf_get_user_email($user_id) {}

/**
 * Get user display name
 *
 * @param int $user_id The user ID
 * @return string
 */
function acf_get_user_display_name($user_id) {}

/**
 * Get user first name
 *
 * @param int $user_id The user ID
 * @return string
 */
function acf_get_user_first_name($user_id) {}

/**
 * Get user last name
 *
 * @param int $user_id The user ID
 * @return string
 */
function acf_get_user_last_name($user_id) {}

/**
 * Get user nickname
 *
 * @param int $user_id The user ID
 * @return string
 */
function acf_get_user_nickname($user_id) {}

/**
 * Get URL for acf update
 *
 * @return string
 */
function acf_get_update_url() {}

/**
 * Get update info
 *
 * @return array
 */
function acf_get_update_info() {}

/**
 * Check update
 *
 * @return array
 */
function acf_check_update() {}

/**
 * Do update
 *
 * @return array
 */
function acf_do_update() {}

/**
 * Include include
 *
 * @param string $file The file path
 * @return void
 */
function acf_include_include($file) {}

/**
 * Verify nonce
 *
 * @param string $nonce The nonce
 * @param string $action The action name
 * @return bool
 */
function acf_verify_nonce($nonce, $action = 'acf_nonce') {}

/**
 * Create nonce
 *
 * @param string $action The action name
 * @return string
 */
function acf_create_nonce($action = 'acf_nonce') {}

/**
 * Get the form
 *
 * @param array $args Form arguments
 * @return string
 */
function acf_get_form($args = array()) {}

/**
 * Validate post id
 *
 * @param int|string $post_id The post ID
 * @return int
 */
function acf_validate_post_id($post_id) {}

/**
 * Is valid post
 *
 * @param int $post_id The post ID
 * @return bool
 */
function acf_is_valid_post($post_id) {}

/**
 * Is valid post id
 *
 * @param int $post_id The post ID
 * @return bool
 */
function acf_is_valid_post_id($post_id) {}

/**
 * Strip tags
 *
 * @param string $text The text
 * @param string $tags The tags to strip
 * @return string
 */
function acf_strip_tags($text, $tags = '<p>') {}

/**
 * The format
 *
 * @param string $text The text
 * @return string
 */
function acf_the_format($text) {}

/**
 * Get wp date format
 *
 * @return string
 */
function acf_get_wp_date_format() {}

/**
 * Add wp magic quotes
 *
 * @return void
 */
function acf_add_wp_magic_quotes() {}

/**
 * Allow filter
 *
 * @param array $array The array
 * @param callable $callback The callback
 * @return array
 */
function array_map($callback, array $array) {}

/**
 * Get a setting
 *
 * @param string $setting The setting name
 * @param mixed $default The default value
 * @return mixed
 */
function acf_setting($setting, $default = null) {}

/**
 * Set a setting
 *
 * @param string $setting The setting name
 * @param mixed $value The value
 * @return void
 */
function acf_update_setting($setting, $value) {}

/**
 * Append a setting
 *
 * @param string $setting The setting name
 * @param mixed $value The value
 * @return void
 */
function acf_append_setting($setting, $value) {}

/**
 * Get settings
 *
 * @return array
 */
function acf_get_settings() {}

/**
 * Update settings
 *
 * @param array $settings The settings array
 * @return void
 */
function acf_update_settings($settings) {}

/**
 * Get a local type
 *
 * @param string $type The local type
 * @return string
 */
function acf_get_local_type($type) {}

/**
 * The notices
 *
 * @param string $text The notice text
 * @param string $type The notice type
 * @return void
 */
function acf_add_notice($text, $type = 'info') {}

/**
 * The error
 *
 * @param string $text The error text
 * @return void
 */
function acf_add_error_notice($text) {}

/**
 * Clear notices
 *
 * @return void
 */
function acf_clear_notices() {}

/**
 * Disable notifications
 *
 * @return void
 */
function acf_disable_notifications() {}

/**
 * Enable notifications
 *
 * @return void
 */
function acf_enable_notifications() {}

/**
 * Get notices
 *
 * @param string $type The notice type
 * @return array
 */
function acf_get_notices($type = '') {}

/**
 * Has notice
 *
 * @return bool
 */
function acf_has_notices() {}

/**
 * Get notice
 *
 * @param string $text The notice text
 * @return array|false
 */
function acf_get_notice($text) {}

/**
 * Remove notice
 *
 * @param string $text The notice text
 * @return void
 */
function acf_remove_notice($text) {}

/**
 * Translation
 *
 * @param string $text The text
 * @return string
 */
function __($text) {}

/**
 * Escape translation
 *
 * @param string $text The text
 * @return string
 */
function esc_html__($text) {}

/**
 * Attribute escape
 *
 * @param string $text The text
 * @return string
 */
function esc_attr__($text) {}

/**
 * E translation
 *
 * @param string $text The text
 * @return void
 */
function _e($text) {}

/**
 * Escape e
 *
 * @param string $text The text
 * @return void
 */
function esc_html_e($text) {}

/**
 * Attribute e
 *
 * @param string $text The text
 * @return void
 */
function esc_attr_e($text) {}

/**
 * Get translation
 *
 * @param string $text The text
 * @param string $domain The domain
 * @return string
 */
function _x($text, $context) {}

/**
 * Translation
 *
 * @param string $text The text
 * @param string $domain The domain
 * @return string
 */
function _ex($text, $context) {}

/**
 * Get plural translation
 *
 * @param int $single Single form
 * @param int $plural Plural form
 * @param int $number The number
 * @param string $domain The domain
 * @return string
 */
function _n($single, $plural, $number) {}

/**
 * Has capability
 *
 * @param string $cap The capability
 * @param array $args Arguments
 * @return bool
 */
function acf_has_capability($cap, $args = array()) {}

/**
 * Has user capability
 *
 * @param string $cap The capability
 * @param int|false $user_id The user ID
 * @return bool
 */
function acf_has_user_capability($cap, $user_id = false) {}

/**
 * Get display locale
 *
 * @return string
 */
function acf_get_display_locale() {}

/**
 * Get available languages
 *
 * @return array
 */
function acf_get_available_languages() {}

/**
 * Get current language
 *
 * @return string
 */
function acf_get_current_language() {}

/**
 * Translate
 *
 * @param string $text The text
 * @param string $domain The domain
 * @return string
 */
function acf_translate($text, $domain = 'default') {}

/**
 * Get_translation
 *
 * @return callable
 */
function acf_get_text_domain() {}

/**
 * Localize
 *
 * @param array $args Arguments
 * @return array
 */
function acf_localize_text($args) {}

/**
 * Filter text
 *
 * @param string $text The text
 * @param string $name The filter name
 * @param mixed $value The value
 * @return mixed
 */
function acf_filter_text($text, $name, $value = true) {}

/**
 * Prepare text
 *
 * @param string $text The text
 * @param array $args Arguments
 * @return string
 */
function acf_text_to_string($text, $args = array()) {}

/**
 * Prepare choice
 *
 * @param array $choices Choices array
 * @param bool $sort Whether to sort
 * @return array
 */
function acf_get_choices($choices, $sort = true) {}

/**
 * Sort keys
 *
 * @param array $a First array
 * @param array $b Second array
 * @return int
 */
function acf_sort_by_key($a, $b) {}

/**
 * Reverse sort keys
 *
 * @param array $a First array
 * @param array $b Second array
 * @return int
 */
function acf_reverse_sort_by_key($a, $b) {}

/**
 * Get versions
 *
 * @return array
 */
function acf_get_versions() {}

/**
 * Pro is available
 *
 * @return bool
 */
function acf_is_pro() {}

/**
 * Is pro
 *
 * @return bool
 */
function acf_pro() {}

/**
 * Is local/json
 *
 * @param int $post_id The post ID
 * @return bool
 */
function acf_is_local_post($post_id) {}

/**
 * Get location types
 *
 * @return array
 */
function acf_get_location_types() {}

/**
 * Get location rules
 *
 * @param string $post_id The post ID
 * @param string $rules_slug The rules slug
 * @return array
 */
function acf_get_location_rules($post_id, $rules_slug) {}

/**
 * Get location rule
 *
 * @param string $post_id The post ID
 * @param string $rule_slug The rule slug
 * @param int $rule_index The rule index
 * @return array|false
 */
function acf_get_location_rule($post_id, $rule_slug, $rule_index) {}

/**
 * Render the location rule
 *
 * @param array $rule The location rule
 * @return void
 */
function acf_render_location_rule($rule) {}

/**
 * Get location values
 *
 * @param string $param The param
 * @param string $choices Any
 * @return array
 */
function acf_get_location_values($param, $choices = 'null') {}

/**
 * Valid rule
 *
 * @param array $rule The rule
 * @param array $field_group The field group
 * @return bool
 */
function acf_validate_location_rule($rule, $field_group = array()) {}

/**
 * Valid rules
 *
 * @param array $rules The rules
 * @param array $field_group The field group
 * @return bool
 */
function acf_validate_location_rules($rules, $field_group = array()) {}

/**
 * Matches rule
 *
 * @param array $rule The rule
 * @param array $field The field
 * @return bool
 */
function acf_matches_location_rule($rule, $field) {}

/**
 * Filter location
 *
 * @param array $rule The rule
 * @param array $field The field
 * @return array
 */
function acf_filter_location_fields($rule, $field) {}

/**
 * Filter by location
 *
 * @param array $field_group The field group
 * @return array
 */
function acf_filter_field_group_by_location($field_group) {}

/**
 * Get the field groups for a location
 *
 * @param array $field The field array
 * @return array
 */
function acf_get_field_groups_for_location($field) {}

/**
 * Get location metaboxes
 *
 * @return array
 */
function acf_get_field_groups_for_location_admin() {}

/**
 * Get field groups
 *
 * @param array $args Arguments
 * @return array
 */
function acf_get_field_groups($args = array()) {}

/**
 * Sort by menu order
 *
 * @param array $a First array
 * @param array $b Second array
 * @return int
 */
function acf_menu_order($a, $b) {}

/**
 * Get post id
 *
 * @param int $post_id The post ID
 * @return int
 */
function acf_get_post_id($post_id = 0) {}

/**
 * Get post
 *
 * @param int $post_id The post ID
 * @return array|false
 */
function acf_get_post($post_id) {}

/**
 * Get posts
 *
 * @param array $args Arguments
 * @return array
 */
function acf_get_posts($args = array()) {}

/**
 * Get post title
 *
 * @param int $post_id The post ID
 * @return string
 */
function acf_get_post_title($post_id) {}

/**
 * Get post type
 *
 * @param int $post_id The post ID
 * @return string
 */
function acf_get_post_type($post_id) {}

/**
 * Get post status
 *
 * @param int $post_id The post ID
 * @return string
 */
function acf_get_post_status($post_id) {}

/**
 * Compare menu order
 *
 * @param array $a First post array
 * @param array $b Second post array
 * @return int
 */
function acf_menu_order_compare($a, $b) {}

/**
 * Decode
 *
 * @param string $data The data
 * @param bool $arr Whether to return array
 * @return mixed
 */
function acf_decode($data, $arr = true) {}

/**
 * Str to json
 *
 * @param string $json The json string
 * @return mixed
 */
function acf_str_to_json($json) {}

/**
 * Json to str
 *
 * @param array|string $json The json
 * @return string
 */
function acf_json_to_str($json) {}

/**
 * Encode
 *
 * @param array $data The data
 * @return string
 */
function acf_encode($data) {}

/**
 * Encode for save
 *
 * @param array $data The data
 * @return string
 */
function acf_encode_for_save($data) {}

/**
 * Encode for update
 *
 * @param array $data The data
 * @return string
 */
function acf_encode_for_update($data) {}

/**
 * Decode value
 *
 * @param string $value The value
 * @return mixed
 */
function acf_decode_value($value) {}

/**
 * Encode value
 *
 * @param mixed $value The value
 * @return string
 */
function acf_encode_value($value) {}

/**
 * Serialize
 *
 * @param mixed $data The data
 * @return string
 */
function acfserialize($data) {}

/**
 * Unserialize
 *
 * @param string $data The serialized data
 * @return mixed
 */
function acf_unserialize($data) {}

/**
 * Is empty
 *
 * @param mixed $value The value
 * @return bool
 */
function acf_is_empty($value) {}

/**
 * Is array
 *
 * @param mixed $value The value
 * @return bool
 */
function acf_is_array($value) {}

/**
 * Has value
 *
 * @param array $field The field array
 * @return bool
 */
function acf_has_value($field) {}

/**
 * Get value
 *
 * @param array $field The field array
 * @return mixed
 */
function acf_get_value($field) {}

/**
 * Format value
 *
 * @param mixed $value The value
 * @param array $field The field array
 * @param int $post_id The post ID
 * @return mixed
 */
function acf_format_value($value, $post_id, $field) {}

/**
 * Update value
 *
 * @param int $post_id The post ID
 * @param string $name The name
 * @param mixed $value The value
 * @return bool
 */
function acf_update_value($value, $post_id, $name) {}

/**
 * Delete value
 *
 * @param int $post_id The post ID
 * @param string $name The name
 * @return bool
 */
function acf_delete_value($post_id, $name) {}

/**
 * Get values
 *
 * @param int $post_id The post ID
 * @return array
 */
function acf_get_values($post_id) {}

/**
 * Copy values
 *
 * @param int $from_post_id The from post ID
 * @param int $to_post_id The to post ID
 * @return void
 */
function acf_copy_values($from_post_id, $to_post_id) {}

/**
 * Get value for context
 *
 * @param mixed $value The value
 * @param array $field The field array
 * @param int $post_id The post ID
 * @return mixed
 */
function acf_get_value_for_api($value, $post_id, $field) {}

/**
 * Get field keys
 *
 * @param array $fields The fields array
 * @param bool $add_prefix Whether to add field_ prefix
 * @return array
 */
function acf_get_field_key($field, $value) {}

/**
 * Is field key
 *
 * @param string $key The key
 * @return bool
 */
function acf_is_field_key($key) {}

/**
 * Get the field key
 *
 * @param string $key The key
 * @return string
 */
function acf_get_field_key($key, $value) {}

/**
 * Get sub field
 *
 * @return array|false
 */
function acf_get_sub_field() {}

/**
 * Get a sub field value
 *
 * @param string $selector The field name or key
 * @param int $post_id The post ID
 * @param bool $format_value Whether to format the value
 * @return mixed
 */
function get_sub_field($selector, $post_id = false, $format_value = true) {}

/**
 * Get the row value
 *
 * @param string $selector The field name or key
 * @param int $post_id The post ID
 * @param bool $format_value Whether to format the value
 * @return mixed
 */
function get_row_field($selector, $post_id = false, $format_value = true) {}

namespace WP {
    class WP_Post {}
    class WP_User {}
    class WP_Error {}
}

namespace {
    /** @var WP_Post|null $post */
    global $post;

    /** @var WP_User|null $current_user */
    global $current_user;

    /** @var WP_User|null $authordata */
    global $authordata;
}