# CHANGELOG

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
