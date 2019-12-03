# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

# server "example.com", user: "deploy", roles: %w{app db web}, my_property: :my_value
# server "example.com", user: "deploy", roles: %w{app web}, other_property: :other_value
# server "db.example.com", user: "deploy", roles: %w{db}
server 'aws-databank-tasks-demo.library.illinois.edu', user: 'databank', roles: %w{app db web}

set :rails_env, 'aws-demo'
set :deploy_to, '/home/databank'

set :ssh_options, {
    forward_agent: true,
    auth_methods: ["publickey"],
    keys: ["#{Dir.home}/.ssh/medusa_prod.pem"]
}
