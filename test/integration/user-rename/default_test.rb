# InSpec test for user-rename suite

title 'User Rename Tests'

# Test for Linux systems
if os.linux?
  describe user('sysadmin') do
    it { should exist }
  end

  # Original root user should not exist or should be renamed
  describe command("getent passwd root | wc -l") do
    its('stdout.strip') { should eq '0' }
  end

  # Verify the renamed user has UID 0 (root privileges)
  describe user('sysadmin') do
    its('uid') { should eq 0 }
  end

  # Verify home directory
  describe file('/root') do
    it { should exist }
    it { should be_directory }
  end

  # Verify group exists
  describe group('sysadmin') do
    it { should exist }
  end
end

# Test for Windows systems
if os.windows?
  describe user('WinAdmin') do
    it { should exist }
  end

  # Original Administrator user should be renamed
  describe powershell('Get-LocalUser -Name Administrator -ErrorAction SilentlyContinue') do
    its('stdout') { should be_empty }
  end

  # Verify the renamed user exists and is enabled
  describe powershell('(Get-LocalUser -Name WinAdmin).Enabled') do
    its('stdout') { should match /True/i }
  end

  # Verify user is in Administrators group
  describe powershell('(Get-LocalGroupMember -Group "Administrators" -Member WinAdmin -ErrorAction SilentlyContinue) -ne $null') do
    its('stdout') { should match /True/i }
  end
end
