# Root Password Rotation Cookbook

A Chef cookbook for managing root (Linux) and Administrator (Windows) password rotation across Amazon Linux, Ubuntu, and Windows Server 2022 systems.

## Description

This cookbook provides a secure and consistent way to rotate administrator passwords and rename administrator accounts across different operating systems. It supports:

- **Linux Systems**: Amazon Linux, Ubuntu (and other Debian/RHEL-based distributions)
  - Change root or custom user passwords
  - Rename root or custom user accounts
  - Rename home directories
- **Windows Systems**: Windows Server 2022 (and other Windows Server versions)
  - Change Administrator or custom user passwords
  - Rename Administrator or custom user accounts
  - Update profile paths and home directories

## Supported Platforms

- Amazon Linux (all versions)
- Ubuntu (14.04+)
- Windows Server 2022
- Other RHEL and Debian-based Linux distributions
- Other Windows Server versions

## Requirements

### Chef
- Chef Client 15.0 or higher

### Cookbooks
No external cookbook dependencies.

## Attributes

### Default Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `['root_password_rotation']['password_source']` | `'data_bag'` | Password source: `'attribute'`, `'data_bag'`, or `'vault'` |
| `['root_password_rotation']['data_bag_name']` | `'passwords'` | Data bag name for password storage |
| `['root_password_rotation']['data_bag_item']` | `'admin'` | Data bag item name |
| `['root_password_rotation']['password']` | `nil` | Password (only used with `password_source = 'attribute'`) |
| `['root_password_rotation']['linux']['username']` | `'root'` | Linux username to manage |
| `['root_password_rotation']['linux']['new_username']` | `nil` | New username for Linux (if renaming) |
| `['root_password_rotation']['linux']['rename_home_dir']` | `true` | Rename home directory when renaming user |
| `['root_password_rotation']['windows']['username']` | `'Administrator'` | Windows username to manage |
| `['root_password_rotation']['windows']['new_username']` | `nil` | New username for Windows (if renaming) |
| `['root_password_rotation']['windows']['rename_home_dir']` | `true` | Rename home directory when renaming user |
| `['root_password_rotation']['windows']['update_profile_path']` | `true` | Update registry profile path when renaming |
| `['root_password_rotation']['log_changes']` | `true` | Log password changes |

### Optional Windows Attributes

| Attribute | Default | Description |
|-----------|---------|-------------|
| `['root_password_rotation']['windows']['password_never_expires']` | Not set | Set password to never expire |
| `['root_password_rotation']['windows']['force_change_on_logon']` | Not set | Force password change on next logon |

## Usage

### Basic Usage

1. **Add to Run List**
   ```ruby
   run_list 'recipe[root-password-rotation]'
   ```

2. **Create Data Bag** (recommended method)

   Create an encrypted data bag for storing passwords:
   
   ```bash
   # Create the data bag
   knife data bag create passwords
   
   # Create an encrypted data bag item
   knife data bag create passwords admin --secret-file ~/.chef/encrypted_data_bag_secret
   ```

   Data bag content example (`passwords/admin.json`):
   ```json
   {
     "id": "admin",
     "linux_password": "YourSecureLinuxPassword123!",
     "windows_password": "YourSecureWindowsPassword123!",
     "amazon_password": "AmazonSpecificPassword123!",
     "ubuntu_password": "UbuntuSpecificPassword123!"
   }
   ```

### Platform-Specific Passwords

The cookbook supports platform-specific passwords. It will look for passwords in this order:

**For Linux:**
1. `<platform>_password` (e.g., `amazon_password`, `ubuntu_password`)
2. `linux_password`
3. `password` (generic fallback)

**For Windows:**
1. `windows_password`
2. `password` (generic fallback)

### Using Node Attributes (Not Recommended for Production)

For testing purposes only, you can set the password via node attributes:

```ruby
node.default['root_password_rotation']['password_source'] = 'attribute'
node.default['root_password_rotation']['password'] = 'TestPassword123!'
```

**Warning**: This method is NOT secure for production as passwords may be visible in node attributes.

### Custom Username

To change a different user's password:

**Linux:**
```ruby
node.default['root_password_rotation']['linux']['username'] = 'admin'
```

**Windows:**
```ruby
node.default['root_password_rotation']['windows']['username'] = 'admin'
```

### Windows-Specific Options

Configure password to never expire:
```ruby
node.default['root_password_rotation']['windows']['password_never_expires'] = true
```

Force password change on next logon:
```ruby
node.default['root_password_rotation']['windows']['force_change_on_logon'] = true
```

### Renaming User Accounts

To rename the root (Linux) or Administrator (Windows) account:

**Linux - Rename root to sysadmin:**
```ruby
node.default['root_password_rotation']['linux']['username'] = 'root'
node.default['root_password_rotation']['linux']['new_username'] = 'sysadmin'
node.default['root_password_rotation']['linux']['rename_home_dir'] = true

include_recipe 'root-password-rotation::linux_user'
```

**Windows - Rename Administrator to WinAdmin:**
```ruby
node.default['root_password_rotation']['windows']['username'] = 'Administrator'
node.default['root_password_rotation']['windows']['new_username'] = 'WinAdmin'
node.default['root_password_rotation']['windows']['rename_home_dir'] = true
node.default['root_password_rotation']['windows']['update_profile_path'] = true

include_recipe 'root-password-rotation::windows_user'
```

**Important Notes:**
- The rename recipes should be run **before** the password rotation recipes
- The new username must not already exist on the system
- For Linux, non-root user processes will be killed before rename (necessary for the operation)
- For Windows, the user should not be logged in when renaming (home directory rename may fail otherwise)
- After renaming, the username attribute is automatically updated to the new name

## Recipes

### default
The main recipe that determines the platform and includes the appropriate platform-specific recipe for password rotation.

### linux
Manages password rotation for Linux systems (Amazon Linux, Ubuntu, RHEL, Debian, etc.).

Features:
- Uses SHA-512 password hashing (modern Linux standard)
- Verifies user exists before attempting password change
- Supports platform-specific passwords
- Secure password handling

### linux_user
Renames a Linux user account (e.g., root to a custom name).

Features:
- Verifies current user exists and new username is available
- Kills user processes (for non-root users) before rename
- Renames user account and associated group
- Optionally renames home directory and updates paths
- Verifies successful rename
- Updates node attributes with new username

### windows
Manages password rotation for Windows systems (Windows Server 2022, etc.).

Features:
- Uses PowerShell and SecureString for secure password handling
- Verifies user exists before attempting password change
- Optional password expiration settings
- Optional force password change on next logon
- Marked as sensitive to prevent password exposure in logs

### windows_user
Renames a Windows user account (e.g., Administrator to a custom name).

Features:
- Verifies current user exists and new username is available
- Renames user account using PowerShell cmdlets
- Optionally updates registry profile paths
- Optionally renames home directory (profile folder)
- Verifies successful rename
- Updates node attributes with new username

## Security Considerations

1. **Use Encrypted Data Bags**: Always use encrypted data bags for storing passwords in production environments.

2. **Sensitive Resource**: The Windows password change operation is marked as `sensitive true` to prevent password exposure in logs.

3. **Password Complexity**: Ensure passwords meet your organization's complexity requirements:
   - Minimum length (typically 12-16 characters)
   - Mix of uppercase, lowercase, numbers, and special characters
   - No dictionary words

4. **Rotation Schedule**: Set up a regular password rotation schedule using Chef's scheduling capabilities or external orchestration.

5. **Audit Logging**: Enable `log_changes` attribute to track when passwords are changed.

6. **User Rename Caution**: Renaming administrator accounts (especially root/Administrator) can impact:
   - Active sessions and running processes
   - Scripts and automation that reference the old username
   - File permissions and ownership
   - Service accounts and scheduled tasks
   - Always test in a non-production environment first

6. **Access Control**: Restrict access to:
   - Encrypted data bag secret
   - Chef Server with appropriate permissions
   - Systems where cookbook is deployed

## Testing

This cookbook includes comprehensive Test Kitchen configuration for testing on AWS EC2 instances.

### Prerequisites

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Configure AWS credentials:**
   ```bash
   export AWS_ACCESS_KEY_ID=your_access_key
   export AWS_SECRET_ACCESS_KEY=your_secret_key
   export AWS_REGION=us-east-1
   ```

3. **Ensure SSH key exists:**
   ```bash
   # The kitchen.yml expects a key named 'chef-testing' in us-east-1
   # Create one if it doesn't exist
   ```

### Running Tests

**List all test instances:**
```bash
bundle exec kitchen list
```

**Test a specific platform:**
```bash
bundle exec kitchen test ubuntu-22-password-rotation
bundle exec kitchen test amazonlinux-2023-user-rename
bundle exec kitchen test windows-2022-password-only
```

**Test all platforms:**
```bash
bundle exec kitchen test
```

**Run specific suite:**
```bash
# Password rotation only
bundle exec kitchen test password-rotation

# User rename with password change
bundle exec kitchen test user-rename

# Password change only (no rename)
bundle exec kitchen test password-only

# User rename only (no password change)
bundle exec kitchen test rename-only
```

### Test Suites

1. **password-rotation**: Tests basic password rotation functionality
2. **user-rename**: Tests renaming user accounts with password rotation
3. **password-only**: Tests password rotation without user rename
4. **rename-only**: Tests user rename without password rotation

### Supported Platforms

- Ubuntu 22.04 LTS
- Amazon Linux 2023
- Windows Server 2022

### InSpec Tests

The cookbook includes InSpec tests in `test/integration/` that verify:
- User existence and properties
- Password changes
- User renames
- Home directory changes
- Group memberships
- Windows profile paths

## Known Issues

### Test Kitchen Windows Testing Limitation

**Issue**: Automated Test Kitchen tests fail on Windows Server 2022 with error:
```
Failed to complete #create action: [no implicit conversion of nil into String 
in the specified region us-east-1. Please check this AMI is available in this region.]
```

**Cause**: This is a known bug in kitchen-ec2 versions 3.19.0-3.21.0 that occurs after Windows administrator password retrieval during WinRM transport setup.

**Status**: The cookbook recipes work correctly on Windows when deployed manually. The issue is limited to the Test Kitchen automation framework, not the cookbook functionality itself.

**Workaround for Manual Windows Testing**:
```bash
# 1. Create a Windows EC2 instance manually via AWS Console or CLI
aws ec2 run-instances \
  --image-id ami-0159172a5a821bafd \
  --instance-type t3.medium \
  --key-name your-key-name \
  --security-group-ids sg-xxxxxx

# 2. Get the Administrator password using your key pair
aws ec2 get-password-data \
  --instance-id i-xxxxxxxx \
  --priv-launch-key /path/to/key.pem

# 3. Bootstrap the instance with Chef
knife bootstrap windows winrm IPADDRESS \
  -x Administrator \
  -P PASSWORD \
  -N windows-test-node

# 4. Upload the cookbook
knife cookbook upload root-password-rotation

# 5. Add to node run list and run chef-client
knife node run_list add windows-test-node 'recipe[root-password-rotation::default]'
knife ssh "name:windows-test-node" "chef-client" -x Administrator
```

**Tested Platforms**: ✅ Amazon Linux 2023, ✅ Ubuntu 22.04, ⚠️ Windows Server 2022 (manual testing required)

### Root User Rename Limitation

**Issue**: Cannot rename the `root` user on Linux while the system is running.

**Error**: `usermod: user root is currently used by process 1`

**Cause**: The root user is in use by system init process (PID 1) and cannot be renamed on a live system.

**Workaround**: 
- Rename non-root administrative users instead
- Or perform root rename during system maintenance/single-user mode (not recommended)
- The cookbook works correctly for renaming other system users

## Troubleshooting

### Password not found
```
ERROR: No password available - skipping password rotation
```
**Solution**: Verify data bag exists and contains the correct password field.

### User does not exist
```
ERROR: User 'username' does not exist on this system
```
**Solution**: Verify the username in attributes matches an existing system user.

### Windows PowerShell errors
**Solution**: Ensure PowerShell 5.0+ is available on Windows systems.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License and Authors

- **Author**: Your Organization
- **License**: Apache-2.0

## Support

For issues and questions:
- GitHub Issues: https://github.com/bassslap/chef-root-password-rotation/issues
- Source Code: https://github.com/bassslap/chef-root-password-rotation
