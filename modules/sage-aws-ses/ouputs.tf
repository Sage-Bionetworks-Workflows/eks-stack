
output "smtp_username" {
  value = aws_iam_access_key.smtp_user.id
}

output "smtp_password" {
  sensitive = true
  value     = aws_iam_access_key.smtp_user.ses_smtp_password_v4
}