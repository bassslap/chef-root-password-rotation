# InSpec test for rename-only suite

title 'Rename Only Tests'

# Test for Linux systems
if os.linux?
  describe user('adminuser') do
    it { should exist }
    its('uid') { should eq 0 }
  end

  # Original root user should be renamed
  describe command("getent passwd root | wc -l") do
    its('stdout.strip') { should eq '0' }
  end

  # Verify the renamed user exists
  describe command('getent passwd adminuser') do
    its('exit_status') { should eq 0 }
  end

  # Verify group was renamed
  describe group('adminuser') do
    it { should exist }
  end
end

# Test for Windows systems
if os.windows?
  describe user('AdminUser') do
    it { should exist }
  end

  # Original Administrator should be renamed
  describe powershell('Get-LocalUser -Name Administrator -ErrorAction SilentlyContinue') do
    its('stdout') { should be_empty }
  end

  # Verify renamed user exists and is enabled
  describe powershell('(Get-LocalUser -Name AdminUser).Enabled') do
    its('stdout') { should match /True/i }
  end

  # Verify user is in Administrators group
  describe powershell('Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.Name -like "*AdminUser" }') do
    its('exit_status') { should eq 0 }
  end
end
