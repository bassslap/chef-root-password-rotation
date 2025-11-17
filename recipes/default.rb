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

Chef::Log.info('Starting root/administrator password rotation cookbook')

# Determine the platform and include the appropriate recipe
case node['platform_family']
when 'rhel', 'amazon', 'debian'
  include_recipe 'root-password-rotation::linux'
when 'windows'
  include_recipe 'root-password-rotation::windows'
else
  Chef::Log.warn("Platform family #{node['platform_family']} is not supported by this cookbook")
end
