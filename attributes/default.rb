#
# Cookbook:: root-password-rotation
# Attribute:: default
#
# Copyright:: 2025, Your Organization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

# Default attributes for password rotation

# Password source - can be 'attribute', 'data_bag', or 'vault'
default['root_password_rotation']['password_source'] = 'data_bag'

# Data bag configuration
default['root_password_rotation']['data_bag_name'] = 'passwords'
default['root_password_rotation']['data_bag_item'] = 'admin'

# Password attribute (used only if password_source is 'attribute')
# WARNING: This is not secure for production use!
default['root_password_rotation']['password'] = nil

# Enable/disable password rotation
default['root_password_rotation']['rotate_password'] = true

# Linux configuration
default['root_password_rotation']['linux']['username'] = 'root'
default['root_password_rotation']['linux']['enforce_password_change'] = true
default['root_password_rotation']['linux']['new_username'] = nil  # Set to rename the user
default['root_password_rotation']['linux']['rename_home_dir'] = true  # Rename home directory when renaming user

# Windows configuration
default['root_password_rotation']['windows']['username'] = 'Administrator'
default['root_password_rotation']['windows']['enforce_password_change'] = true
default['root_password_rotation']['windows']['new_username'] = nil  # Set to rename the user
default['root_password_rotation']['windows']['rename_home_dir'] = true  # Rename home directory when renaming user
default['root_password_rotation']['windows']['update_profile_path'] = true  # Update registry profile path

# Logging
default['root_password_rotation']['log_changes'] = true
