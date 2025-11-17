# Example: Windows-specific configuration

# Set password to never expire
node.default['root_password_rotation']['windows']['password_never_expires'] = true

# OR force password change on next logon
# node.default['root_password_rotation']['windows']['force_change_on_logon'] = true

# Use custom administrator account name
node.default['root_password_rotation']['windows']['username'] = 'Administrator'

# Use encrypted data bag for password
node.default['root_password_rotation']['password_source'] = 'data_bag'
node.default['root_password_rotation']['data_bag_name'] = 'passwords'
node.default['root_password_rotation']['data_bag_item'] = 'admin'

include_recipe 'root-password-rotation::windows'
