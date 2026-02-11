# Folders for organization
resource "grafana_folder" "infrastructure" {
  title = "Infrastructure"
  uid   = "infrastructure"
}

resource "grafana_folder" "applications" {
  title = "Applications"
  uid   = "applications"
}

resource "grafana_folder" "security" {
  title = "Security"
  uid   = "security"
}

# Dashboard permissions
resource "grafana_folder_permission" "infrastructure" {
  folder_uid = grafana_folder.infrastructure.uid

  permissions {
    role       = "Viewer"
    permission = "View"
  }

  permissions {
    role       = "Editor"
    permission = "Edit"
  }
}

resource "grafana_folder_permission" "applications" {
  folder_uid = grafana_folder.applications.uid

  permissions {
    role       = "Viewer"
    permission = "View"
  }

  permissions {
    role       = "Editor"
    permission = "Edit"
  }
}

resource "grafana_folder_permission" "security" {
  folder_uid = grafana_folder.security.uid

  permissions {
    role       = "Admin"
    permission = "Admin"
  }
}
