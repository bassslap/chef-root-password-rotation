# Example: Complete usage scenarios

# ============================================
# Scenario 1: Only rotate password (default behavior)
# ============================================
node.default['root_password_rotation']['rotate_password'] = true
node.default['root_password_rotation']['password_source'] = 'data_bag'
# Don't set new_username - no rename will occur

include_recipe 'root-password-rotation::default'

# ============================================
# Scenario 2: Only rename user (no password change)
# ============================================
node.default['root_password_rotation']['rotate_password'] = false  # Disable password rotation
node.default['root_password_rotation']['linux']['username'] = 'root'
node.default['root_password_rotation']['linux']['new_username'] = 'sysadmin'

include_recipe 'root-password-rotation::default'

# ============================================
# Scenario 3: Both rename and rotate password
# ============================================
node.default['root_password_rotation']['rotate_password'] = true
node.default['root_password_rotation']['linux']['username'] = 'root'
node.default['root_password_rotation']['linux']['new_username'] = 'sysadmin'

include_recipe 'root-password-rotation::default'

# ============================================
# Scenario 4: Platform-specific operations
# ============================================

# Linux only - rename and change password
node.default['root_password_rotation']['linux']['username'] = 'root'
node.default['root_password_rotation']['linux']['new_username'] = 'sysadmin'
node.default['root_password_rotation']['linux']['rename_home_dir'] = true

include_recipe 'root-password-rotation::linux_user'     # Rename first
include_recipe 'root-password-rotation::linux_password' # Then change password

# Windows only - rename and change password
node.default['root_password_rotation']['windows']['username'] = 'Administrator'
node.default['root_password_rotation']['windows']['new_username'] = 'WinAdmin'
node.default['root_password_rotation']['windows']['rename_home_dir'] = true
node.default['root_password_rotation']['windows']['update_profile_path'] = true

include_recipe 'root-password-rotation::windows_user'     # Rename first
include_recipe 'root-password-rotation::windows_password' # Then change password
