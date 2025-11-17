# Root Password Rotation Cookbook

A Chef cookbook for managing root (Linux) and Administrator (Windows) password rotation across Amazon Linux, Ubuntu, and Windows Server 2022 systems.

## Description

This cookbook provides a secure and consistent way to rotate administrator passwords across different operating systems. It supports:

- **Linux Systems**: Amazon Linux, Ubuntu (and other Debian/RHEL-based distributions)
- **Windows Systems**: Windows Server 2022 (and other Windows Server versions)

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
| `['root_password_rotation']['windows']['username']` | `'Administrator'` | Windows username to manage |
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

## Recipes

### default
The main recipe that determines the platform and includes the appropriate platform-specific recipe.

### linux
Manages password rotation for Linux systems (Amazon Linux, Ubuntu, RHEL, Debian, etc.).

Features:
- Uses SHA-512 password hashing (modern Linux standard)
- Verifies user exists before attempting password change
- Supports platform-specific passwords
- Secure password handling

### windows
Manages password rotation for Windows systems (Windows Server 2022, etc.).

Features:
- Uses PowerShell and SecureString for secure password handling
- Verifies user exists before attempting password change
- Optional password expiration settings
- Optional force password change on next logon
- Marked as sensitive to prevent password exposure in logs

## Security Considerations

1. **Use Encrypted Data Bags**: Always use encrypted data bags for storing passwords in production environments.

2. **Sensitive Resource**: The Windows password change operation is marked as `sensitive true` to prevent password exposure in logs.

3. **Password Complexity**: Ensure passwords meet your organization's complexity requirements:
   - Minimum length (typically 12-16 characters)
   - Mix of uppercase, lowercase, numbers, and special characters
   - No dictionary words

4. **Rotation Schedule**: Set up a regular password rotation schedule using Chef's scheduling capabilities or external orchestration.

5. **Audit Logging**: Enable `log_changes` attribute to track when passwords are changed.

6. **Access Control**: Restrict access to:
   - Encrypted data bag secret
   - Chef Server with appropriate permissions
   - Systems where cookbook is deployed

## Testing

### Kitchen Configuration Example

```yaml
---
driver:
  name: vagrant

provisioner:
  name: chef_zero
  encrypted_data_bag_secret_key_path: test/integration/encrypted_data_bag_secret

platforms:
  - name: ubuntu-22.04
  - name: amazonlinux-2023
  - name: windows-2022

suites:
  - name: default
    run_list:
      - recipe[root-password-rotation::default]
    attributes:
```

### Test Password Setup

Create a test encrypted data bag secret:
```bash
openssl rand -base64 512 | tr -d '\r\n' > test/integration/encrypted_data_bag_secret
```

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
