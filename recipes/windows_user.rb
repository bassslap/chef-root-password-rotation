#
# Cookbook:: root-password-rotation
# Recipe:: windows_user
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
current_username = node['root_password_rotation']['windows']['username']
new_username = node['root_password_rotation']['windows']['new_username']

# Only proceed if new_username is set
if new_username.nil? || new_username.empty?
  Chef::Log.info('No new username specified for Windows - skipping user rename')
  return
end

# Don't proceed if usernames are the same
if current_username == new_username
  Chef::Log.info('Current and new usernames are the same - skipping user rename')
  return
end

Chef::Log.info("Renaming Windows user from '#{current_username}' to '#{new_username}'")

# Verify the current user exists
powershell_script 'verify_current_windows_user_exists' do
  code <<-PWSH
    $currentUsername = '#{current_username}'
    $user = Get-LocalUser -Name $currentUsername -ErrorAction SilentlyContinue
    if ($null -eq $user) {
      Write-Error "Current user '$currentUsername' does not exist on this system"
      exit 1
    }
    Write-Output "Verified that user '$currentUsername' exists"
  PWSH
  action :run
end

# Check if new username already exists
powershell_script 'check_new_windows_username_available' do
  code <<-PWSH
    $newUsername = '#{new_username}'
    $user = Get-LocalUser -Name $newUsername -ErrorAction SilentlyContinue
    if ($null -ne $user) {
      Write-Error "New username '$newUsername' already exists on this system"
      exit 1
    }
    Write-Output "Verified that username '$newUsername' is available"
  PWSH
  action :run
end

# Rename the Windows user account
powershell_script 'rename_windows_user' do
  code <<-PWSH
    $currentUsername = '#{current_username}'
    $newUsername = '#{new_username}'
    
    try {
      # Get the user object
      $user = Get-LocalUser -Name $currentUsername -ErrorAction Stop
      
      # Rename the user
      Rename-LocalUser -Name $currentUsername -NewName $newUsername -ErrorAction Stop
      
      Write-Output "Successfully renamed user from '$currentUsername' to '$newUsername'"
      exit 0
    } catch {
      Write-Error "Failed to rename user: $($_.Exception.Message)"
      exit 1
    }
  PWSH
  action :run
  notifies :write, 'log[windows_user_renamed]', :immediately if node['root_password_rotation']['log_changes']
end

# Update the profile path in registry if needed
powershell_script 'update_profile_path' do
  code <<-PWSH
    $currentUsername = '#{current_username}'
    $newUsername = '#{new_username}'
    
    # Get the user's SID
    $user = Get-LocalUser -Name $newUsername -ErrorAction Stop
    $sid = $user.SID.Value
    
    # Update profile path in registry
    $profilePath = "Registry::HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\ProfileList\\$sid"
    
    if (Test-Path $profilePath) {
      $currentProfileImagePath = Get-ItemProperty -Path $profilePath -Name "ProfileImagePath" -ErrorAction SilentlyContinue
      
      if ($currentProfileImagePath.ProfileImagePath -match $currentUsername) {
        $newProfileImagePath = $currentProfileImagePath.ProfileImagePath -replace $currentUsername, $newUsername
        Set-ItemProperty -Path $profilePath -Name "ProfileImagePath" -Value $newProfileImagePath
        Write-Output "Updated profile path from '$($currentProfileImagePath.ProfileImagePath)' to '$newProfileImagePath'"
      }
    }
  PWSH
  action :run
  only_if { node['root_password_rotation']['windows']['update_profile_path'] }
end

# Rename the user's home directory (profile folder)
powershell_script 'rename_windows_home_directory' do
  code <<-PWSH
    $currentUsername = '#{current_username}'
    $newUsername = '#{new_username}'
    
    $oldProfilePath = "C:\\Users\\$currentUsername"
    $newProfilePath = "C:\\Users\\$newUsername"
    
    if (Test-Path $oldProfilePath) {
      try {
        # Rename the directory
        Rename-Item -Path $oldProfilePath -NewName $newUsername -ErrorAction Stop
        Write-Output "Successfully renamed home directory from '$oldProfilePath' to '$newProfilePath'"
      } catch {
        Write-Warning "Could not rename home directory: $($_.Exception.Message)"
        Write-Warning "The user may need to log out for this to complete"
      }
    } else {
      Write-Output "Home directory '$oldProfilePath' does not exist or already renamed"
    }
  PWSH
  action :run
  only_if { node['root_password_rotation']['windows']['rename_home_dir'] }
  notifies :write, 'log[windows_home_dir_renamed]', :immediately if node['root_password_rotation']['log_changes']
end

# Update node attribute to reflect the new username
ruby_block 'update_windows_username_attribute' do
  block do
    node.override['root_password_rotation']['windows']['username'] = new_username
    Chef::Log.info("Updated username attribute to '#{new_username}'")
  end
  action :run
end

# Log messages
log 'windows_user_renamed' do
  message "Windows user account renamed from '#{current_username}' to '#{new_username}'"
  level :info
  action :nothing
end

log 'windows_home_dir_renamed' do
  message "Home directory renamed for Windows user '#{new_username}'"
  level :info
  action :nothing
end

# Verify the rename was successful
powershell_script 'verify_windows_user_rename' do
  code <<-PWSH
    $newUsername = '#{new_username}'
    $user = Get-LocalUser -Name $newUsername -ErrorAction SilentlyContinue
    
    if ($null -eq $user) {
      Write-Error "Failed to verify that user was renamed to '$newUsername'"
      exit 1
    }
    
    Write-Output "Successfully verified user rename to '$newUsername'"
    exit 0
  PWSH
  action :run
end
