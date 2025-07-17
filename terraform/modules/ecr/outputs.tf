output "frontend_repo_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "backend_go_repo_url" {
  value = aws_ecr_repository.backend_go.repository_url
}

output "backend_py_repo_url" {
  value = aws_ecr_repository.backend_py.repository_url
}
