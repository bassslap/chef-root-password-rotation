#
# Cookbook:: root-password-rotation
# Recipe:: linux
#
# Copyright:: 2025, Your Organization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#

# Get the username from attributes
username = node['root_password_rotation']['linux']['username']

Chef::Log.info("Managing password for Linux user: #{username}")

# Retrieve password based on configured source
password = case node['root_password_rotation']['password_source']
when 'data_bag'
  # Retrieve password from encrypted data bag
  begin
    data_bag_name = node['root_password_rotation']['data_bag_name']
    data_bag_item_name = node['root_password_rotation']['data_bag_item']
    
    password_item = data_bag_item(data_bag_name, data_bag_item_name)
    
    # Try to get platform-specific password first, then fall back to generic
    password_item["#{node['platform']}_password"] || 
    password_item['linux_password'] || 
    password_item['password']
  rescue Net::HTTPClientException, Chef::Exceptions::InvalidDataBagPath => e
    Chef::Log.error("Failed to retrieve password from data bag: #{e.message}")
    Chef::Log.error("Make sure data bag '#{data_bag_name}' and item '#{data_bag_item_name}' exist")
    nil
  end
when 'attribute'
  # Use password from node attribute (NOT recommended for production)
  Chef::Log.warn('Using password from node attributes - this is not secure for production!')
  node['root_password_rotation']['password']
else
  Chef::Log.error("Invalid password source: #{node['root_password_rotation']['password_source']}")
  nil
end

# Only proceed if we have a password
if password.nil? || password.empty?
  Chef::Log.error('No password available - skipping password rotation')
  return
end

# Generate password hash for Linux
# Using SHA-512 (recommended for modern Linux systems)
ruby_block 'generate_password_hash' do
  block do
    require 'securerandom'
    
    # Generate a random salt
    salt = SecureRandom.hex(8)
    
    # Create the password hash using openssl
    hash_cmd = Mixlib::ShellOut.new(
      "openssl passwd -6 -salt #{salt} '#{password}'"
    )
    hash_cmd.run_command
    hash_cmd.error!
    
    password_hash = hash_cmd.stdout.strip
    
    # Store the hash in a node run_state for use by the user resource
    node.run_state['password_hash'] = password_hash
  end
  action :run
end

# Update the user password
user username do
  password lazy { node.run_state['password_hash'] }
  action :modify
  notifies :write, 'log[password_changed]', :immediately if node['root_password_rotation']['log_changes']
end

# Log password change (optional)
log 'password_changed' do
  message "Password for user '#{username}' has been updated successfully on #{node['platform']} #{node['platform_version']}"
  level :info
  action :nothing
end

# Verify the user exists
ruby_block 'verify_user_exists' do
  block do
    unless File.exist?('/etc/passwd')
      raise "Cannot verify user - /etc/passwd not found"
    end
    
    user_exists = false
    File.open('/etc/passwd', 'r') do |file|
      file.each_line do |line|
        if line.start_with?("#{username}:")
          user_exists = true
          break
        end
      end
    end
    
    unless user_exists
      raise "User '#{username}' does not exist on this system"
    end
    
    Chef::Log.info("Verified that user '#{username}' exists")
  end
  action :run
end
