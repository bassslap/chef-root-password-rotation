# Example: Using attributes for password (NOT RECOMMENDED FOR PRODUCTION)

# WARNING: This method stores passwords in plain text in node attributes
# Only use for testing/development environments

node.default['root_password_rotation']['password_source'] = 'attribute'
node.default['root_password_rotation']['password'] = 'TestPassword123!'

include_recipe 'root-password-rotation::default'
