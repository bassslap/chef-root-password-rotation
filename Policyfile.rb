# Policyfile for root-password-rotation cookbook
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile/

name 'root-password-rotation'

# Where to find external cookbooks:
default_source :supermarket

# Run list
run_list 'root-password-rotation::default'

# Cookbook versions
cookbook 'root-password-rotation', path: '.'

# Attributes
default['root_password_rotation']['password_source'] = 'data_bag'
default['root_password_rotation']['data_bag_name'] = 'passwords'
default['root_password_rotation']['data_bag_item'] = 'admin'
