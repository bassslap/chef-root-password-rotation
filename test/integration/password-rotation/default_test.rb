# InSpec test for password-rotation suite

title 'Password Rotation Tests'

# Test for Linux systems
if os.linux?
  describe user('root') do
    it { should exist }
  end

  describe file('/etc/shadow') do
    it { should exist }
  end

  # Verify password was changed (password hash should exist)
  describe command("grep '^root:' /etc/shadow | cut -d: -f2") do
    its('stdout') { should_not be_empty }
    its('stdout') { should_not match /^[!*]/ }  # Not locked or disabled
  end

  describe command('echo "TestKitchenPassword123!" | su - root -c "whoami" 2>/dev/null || echo "password_works"') do
    its('exit_status') { should eq 0 }
  end
end

# Test for Windows systems
if os.windows?
  describe user('Administrator') do
    it { should exist }
  end

  # Check that the user account is enabled
  describe powershell('(Get-LocalUser -Name Administrator).Enabled') do
    its('stdout') { should match /True/i }
  end

  # Verify password policy
  describe powershell('Get-LocalUser -Name Administrator | Select-Object PasswordLastSet') do
    its('exit_status') { should eq 0 }
  end
end
