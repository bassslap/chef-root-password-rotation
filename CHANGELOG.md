# CHANGELOG

## 1.1.0 (2025-11-17)

### Features
- Added user account renaming functionality for Linux systems
- Added user account renaming functionality for Windows systems
- New recipe: `linux_user` for renaming Linux users (including root)
- New recipe: `windows_user` for renaming Windows users (including Administrator)
- Automatic home directory renaming support for both platforms
- Windows registry profile path updates when renaming users
- Comprehensive verification and error handling for rename operations
- Updated documentation with rename examples and best practices

### Improvements
- Enhanced attributes with rename-related configuration options
- Added safety checks to prevent renaming to existing usernames
- Process management for Linux user renames (kills user processes)
- Registry path updates for Windows profile consistency

## 1.0.0 (2025-11-17)

### Features
- Initial release of root-password-rotation cookbook
- Support for Linux password rotation (Amazon Linux, Ubuntu, RHEL, Debian)
- Support for Windows password rotation (Windows Server 2022+)
- Encrypted data bag support for secure password storage
- Platform-specific password configuration
- SHA-512 password hashing for Linux systems
- PowerShell-based secure password management for Windows
- User existence verification before password changes
- Configurable username support (not limited to root/Administrator)
- Optional password expiration settings for Windows
- Optional force password change on logon for Windows
- Comprehensive logging and error handling
- Example configurations and data bag structures
