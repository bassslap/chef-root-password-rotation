#
# Cookbook:: root-password-rotation
# Recipe:: windows
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
username = node['root_password_rotation']['windows']['username']

Chef::Log.info("Managing password for Windows user: #{username}")

# Retrieve password based on configured source
password = case node['root_password_rotation']['password_source']
           when 'data_bag'
             # Retrieve password from encrypted data bag
             begin
               data_bag_name = node['root_password_rotation']['data_bag_name']
               data_bag_item_name = node['root_password_rotation']['data_bag_item']

               password_item = data_bag_item(data_bag_name, data_bag_item_name)

               # Try to get platform-specific password first, then fall back to generic
               password_item['windows_password'] ||
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

# Verify the user exists first
powershell_script 'verify_windows_user_exists' do
  code <<-PWSH
    $username = '#{username}'
    $user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue
    if ($null -eq $user) {
      Write-Error "User '$username' does not exist on this system"
      exit 1
    }
    Write-Output "Verified that user '$username' exists"
  PWSH
  action :run
end

# Change the Windows password using PowerShell
powershell_script 'change_windows_password' do
  code <<-PWSH
    $username = '#{username}'
    $password = '#{password}'

    # Convert password to SecureString
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force

    # Get the user object
    $user = Get-LocalUser -Name $username -ErrorAction Stop

    # Set the password
    $user | Set-LocalUser -Password $securePassword

    # Verify the password was set
    if ($?) {
      Write-Output "Password for user '$username' has been updated successfully"
      exit 0
    } else {
      Write-Error "Failed to update password for user '$username'"
      exit 1
    }
  PWSH
  sensitive true
  action :run
  notifies :write, 'log[windows_password_changed]', :immediately if node['root_password_rotation']['log_changes']
end

# Log password change (optional)
log 'windows_password_changed' do
  message "Password for user '#{username}' has been updated successfully on Windows Server #{node['platform_version']}"
  level :info
  action :nothing
end

# Optional: Set password to never expire
powershell_script 'set_password_never_expires' do
  code <<-PWSH
    $username = '#{username}'
    Set-LocalUser -Name $username -PasswordNeverExpires $true
    Write-Output "Set password to never expire for user '$username'"
  PWSH
  action :run
  only_if { node['root_password_rotation']['windows']['password_never_expires'] }
end

# Optional: Force password change on next logon (useful for initial setup)
powershell_script 'force_password_change_on_logon' do
  code <<-PWSH
    $username = '#{username}'
    $user = Get-LocalUser -Name $username
    $user | Set-LocalUser -PasswordNeverExpires $false

    # Use net user command as Set-LocalUser doesn't have a direct option
    net user $username /logonpasswordchg:yes

    Write-Output "User '$username' will be required to change password on next logon"
  PWSH
  action :run
  only_if { node['root_password_rotation']['windows']['force_change_on_logon'] }
end
