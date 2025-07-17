resource "aws_ecr_repository" "frontend" {
  name = "shortlink-frontend"
}

resource "aws_ecr_repository" "backend_go" {
  name = "shortlink-backend-go"
}

resource "aws_ecr_repository" "backend_py" {
  name = "shortlink-backend-py"
}
