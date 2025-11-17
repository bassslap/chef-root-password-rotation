# Example: Renaming root or Administrator account

# Linux - Rename root to sysadmin
node.default['root_password_rotation']['linux']['username'] = 'root'
node.default['root_password_rotation']['linux']['new_username'] = 'sysadmin'
node.default['root_password_rotation']['linux']['rename_home_dir'] = true

# Windows - Rename Administrator to WinAdmin
node.default['root_password_rotation']['windows']['username'] = 'Administrator'
node.default['root_password_rotation']['windows']['new_username'] = 'WinAdmin'
node.default['root_password_rotation']['windows']['rename_home_dir'] = true
node.default['root_password_rotation']['windows']['update_profile_path'] = true

# Include the rename recipe first, then password rotation
include_recipe 'root-password-rotation::linux_user' # For Linux
# OR
include_recipe 'root-password-rotation::windows_user' # For Windows

# Then rotate the password for the renamed user
include_recipe 'root-password-rotation::default'
