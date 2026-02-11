# Output the n8n provider ID (automatically bound to the Embedded Outpost)
output "n8n_provider_id" {
  description = "ID of the n8n Proxy Provider (bound to Embedded Outpost)"
  value       = module.n8n.provider_id
}

# Output the embedded outpost ID for reference
output "embedded_outpost_id" {
  description = "ID of the Authentik Embedded Outpost"
  value       = authentik_outpost.embedded.id
}
