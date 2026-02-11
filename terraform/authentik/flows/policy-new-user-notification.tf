# Policy to send email notification to admins/delegates when a new user reaches the welcome stage
resource "authentik_policy_expression" "new_user_notification" {
  name              = "policy-new-user-notification"
  execution_logging = true
  expression        = <<-EOT
from django.core.mail import send_mail
from authentik.core.models import Group

# Resolve user from context
user = request.user
if not user or not user.is_authenticated:
    if 'user' in context:
        user = context['user']
    elif 'pending_user' in context:
        user = context['pending_user']

# If we still don't have a valid user object (shouldn't happen after user_write), abort
if not user or not hasattr(user, 'email'):
    ak_logger.warning("No valid user found in context for notification")
    return True

# Idempotency check
if user.attributes.get("enrollment_notification_sent", False):
    return True

# Get user details
user_email = user.email
user_username = user.username

# Prepare email
subject = f"New User Enrollment: {user_email}"
body = f"""A new user has enrolled in the platform.

Username: {user_username}
Email: {user_email}

Please review this user and activate their account if appropriate.
"""

# Collect recipients
recipients = set()
target_groups = ["admin", "union-delegate"]

for group_name in target_groups:
    try:
        group = Group.objects.get(name=group_name)
        # Add all active users with emails
        for member in group.users.filter(is_active=True):
            if member.email:
                recipients.add(member.email)
    except Group.DoesNotExist:
        ak_logger.warning(f"Group {group_name} not found when sending notifications")

if not recipients:
    ak_logger.warning("No recipients found for new user notification")
    return True

# Send email
try:
    send_mail(
        subject=subject,
        message=body,
        from_email=None,
        recipient_list=list(recipients),
        fail_silently=False
    )
    ak_logger.info(f"Sent enrollment notification for {user_email} to {len(recipients)} recipients")
    
    # Mark as sent
    user.attributes["enrollment_notification_sent"] = True
    user.save()
    
except Exception as e:
    ak_logger.error(f"Failed to send enrollment notification: {e}")

return True
EOT
}

# Bind to Source Enrollment Welcome Stage
resource "authentik_policy_binding" "source_enrollment_notification_binding" {
  target  = authentik_flow_stage_binding.source_enrollment_welcome_binding.id
  policy  = authentik_policy_expression.new_user_notification.id
  order   = 0
  enabled = true
  timeout = 30
}

# Bind to Manual Enrollment Welcome Stage
resource "authentik_policy_binding" "manual_enrollment_notification_binding" {
  target  = authentik_flow_stage_binding.manual_enrollment_welcome_binding.id
  policy  = authentik_policy_expression.new_user_notification.id
  order   = 0
  enabled = true
  timeout = 30
}
