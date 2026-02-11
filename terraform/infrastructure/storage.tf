
# =============================================================================
# STORAGE CONFIGURATION
# =============================================================================
# This file is intentionally minimal for upstream.
# All actual storage resources are defined in storage_local.tf.
#
# For new deployments:
# 1. Copy storage_local.tf.example to storage_local.tf
# 2. Customize bucket names, CORS origins, and database settings
# 3. Ensure bucket names are globally unique (use your org prefix)
# =============================================================================

# Storage resources are defined in storage_local.tf
# See storage_local.tf.example for a template with:
# - Object storage buckets (appdata, traefik-acme)
# - PostgreSQL managed database instance
