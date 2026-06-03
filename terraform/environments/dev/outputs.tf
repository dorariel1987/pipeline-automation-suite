output "aks_cluster_name" { value = module.aks.cluster_name }
output "aks_resource_group" { value = module.networking.resource_group_name }
output "acr_login_server" { value = module.acr.login_server }
output "key_vault_name" { value = module.key_vault.name }
output "key_vault_uri" { value = module.key_vault.uri }
