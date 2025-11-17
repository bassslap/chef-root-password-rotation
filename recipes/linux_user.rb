#
# Cookbook:: root-password-rotation
# Recipe:: linux_user
#
# Copyright:: 2025, Your Organization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

# Get the current and new usernames from attributes
current_username = node['root_password_rotation']['linux']['username']
new_username = node['root_password_rotation']['linux']['new_username']

# Only proceed if new_username is set
if new_username.nil? || new_username.empty?
  Chef::Log.info('No new username specified for Linux - skipping user rename')
  return
end

# Don't proceed if usernames are the same
if current_username == new_username
  Chef::Log.info('Current and new usernames are the same - skipping user rename')
  return
end

Chef::Log.info("Renaming Linux user from '#{current_username}' to '#{new_username}'")

# Verify the current user exists
ruby_block 'verify_current_user_exists' do
  block do
    unless File.exist?('/etc/passwd')
      raise 'Cannot verify user - /etc/passwd not found'
    end

    user_exists = false
    File.open('/etc/passwd', 'r') do |file|
      file.each_line do |line|
        if line.start_with?("#{current_username}:")
          user_exists = true
          break
        end
      end
    end

    unless user_exists
      raise "Current user '#{current_username}' does not exist on this system"
    end

    Chef::Log.info("Verified that user '#{current_username}' exists")
  end
  action :run
end

# Check if new username already exists
ruby_block 'check_new_username_available' do
  block do
    user_exists = false
    File.open('/etc/passwd', 'r') do |file|
      file.each_line do |line|
        if line.start_with?("#{new_username}:")
          user_exists = true
          break
        end
      end
    end

    if user_exists
      raise "New username '#{new_username}' already exists on this system"
    end

    Chef::Log.info("Verified that username '#{new_username}' is available")
  end
  action :run
end

# Get current user info for home directory path
ruby_block 'get_user_home_directory' do
  block do
    require 'etc'
    user_info = Etc.getpwnam(current_username)
    node.run_state['old_home_dir'] = user_info.dir
    node.run_state['user_uid'] = user_info.uid
    node.run_state['user_gid'] = user_info.gid
    Chef::Log.info("Current home directory: #{user_info.dir}")
  end
  action :run
end

# Kill any processes running as the user (necessary for rename)
execute 'kill_user_processes' do
  command "pkill -u #{current_username} || true"
  action :run
  only_if { current_username != 'root' } # Don't kill root processes
end

# Rename the user account
execute 'rename_user_account' do
  command "usermod -l #{new_username} #{current_username}"
  action :run
  notifies :write, 'log[user_renamed]', :immediately if node['root_password_rotation']['log_changes']
end

# Rename the user's group (if it matches the username)
execute 'rename_user_group' do
  command "groupmod -n #{new_username} #{current_username}"
  action :run
  only_if "getent group #{current_username}"
  notifies :write, 'log[group_renamed]', :immediately if node['root_password_rotation']['log_changes']
end

# Rename home directory if requested
execute 'rename_home_directory' do
  command lazy {
    old_home = node.run_state['old_home_dir']
    new_home = old_home.gsub("/#{current_username}", "/#{new_username}")
    "usermod -d #{new_home} -m #{new_username}"
  }
  action :run
  only_if { node['root_password_rotation']['linux']['rename_home_dir'] }
  notifies :write, 'log[home_dir_renamed]', :immediately if node['root_password_rotation']['log_changes']
end

# Update node attribute to reflect the new username
ruby_block 'update_username_attribute' do
  block do
    node.override['root_password_rotation']['linux']['username'] = new_username
    Chef::Log.info("Updated username attribute to '#{new_username}'")
  end
  action :run
end

# Log messages
log 'user_renamed' do
  message "User account renamed from '#{current_username}' to '#{new_username}'"
  level :info
  action :nothing
end

log 'group_renamed' do
  message "User group renamed from '#{current_username}' to '#{new_username}'"
  level :info
  action :nothing
end

log 'home_dir_renamed' do
  message "Home directory renamed for user '#{new_username}'"
  level :info
  action :nothing
end

# Verify the rename was successful
ruby_block 'verify_user_rename' do
  block do
    user_exists = false
    File.open('/etc/passwd', 'r') do |file|
      file.each_line do |line|
        if line.start_with?("#{new_username}:")
          user_exists = true
          break
        end
      end
    end

    unless user_exists
      raise "Failed to verify that user was renamed to '#{new_username}'"
    end

    Chef::Log.info("Successfully verified user rename to '#{new_username}'")
  end
  action :run
end
