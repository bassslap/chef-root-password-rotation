# InSpec test for password-only suite

title 'Password Only Tests'

# Test for Linux systems
if os.linux?
  describe user('root') do
    it { should exist }
    its('uid') { should eq 0 }
  end

  # Verify password was changed
  describe file('/etc/shadow') do
    it { should exist }
  end

  describe command("grep '^root:' /etc/shadow | cut -d: -f2") do
    its('stdout') { should_not be_empty }
    its('stdout') { should_not match /^[!*]/ }
  end

  # Username should still be root
  describe command('whoami') do
    its('stdout.strip') { should eq 'root' }
  end
end

# Test for Windows systems
if os.windows?
  describe user('Administrator') do
    it { should exist }
  end

  # Verify account is enabled
  describe powershell('(Get-LocalUser -Name Administrator).Enabled') do
    its('stdout') { should match /True/i }
  end

  # Verify password was set
  describe powershell('Get-LocalUser -Name Administrator | Select-Object PasswordLastSet') do
    its('exit_status') { should eq 0 }
    its('stdout') { should_not match /1\/1\/1970/ }
  end
end
