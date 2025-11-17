# Example: Using with different usernames

# For Linux systems - change a custom user instead of root
node.default['root_password_rotation']['linux']['username'] = 'ubuntu'

# For Windows systems - change a custom user instead of Administrator
node.default['root_password_rotation']['windows']['username'] = 'sysadmin'

# Include the recipe
include_recipe 'root-password-rotation::default'
