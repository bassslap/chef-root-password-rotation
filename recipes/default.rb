#
# Cookbook:: root-password-rotation
# Recipe:: default
#
# Copyright:: 2025, Your Organization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

Chef::Log.info('Starting root/administrator and password rotation cookbook')

# Determine the platform and include the appropriate recipe
case node['platform_family']
when 'rhel', 'amazon', 'debian'
  # Check if user rename is requested
  new_username = node['root_password_rotation']['linux']['new_username']
  if new_username && !new_username.empty?
    Chef::Log.info('User rename requested - running linux_user recipe first')
    include_recipe 'root-password-rotation::linux_user'
  end
  
  # Run password rotation if enabled
  if node['root_password_rotation']['rotate_password'] == true
    include_recipe 'root-password-rotation::linux_password'
  else
    Chef::Log.info('Password rotation is disabled - skipping linux password recipe')
  end
  
when 'windows'
  # Check if user rename is requested
  new_username = node['root_password_rotation']['windows']['new_username']
  if new_username && !new_username.empty?
    Chef::Log.info('User rename requested - running windows_user recipe first')
    include_recipe 'root-password-rotation::windows_user'
  end
  
  # Run password rotation if enabled
  if node['root_password_rotation']['rotate_password'] == true
    include_recipe 'root-password-rotation::windows_password'
  else
    Chef::Log.info('Password rotation is disabled - skipping windows password recipe')
  end
  
else
  Chef::Log.warn("Platform family #{node['platform_family']} is not supported by this cookbook")
end
