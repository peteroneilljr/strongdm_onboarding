resource "random_password" "db_postgres_pw" {
  length           = 26
  special          = true
  override_special = "!#$%&*()-_=+:?"
}
resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow Postgres inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Postgres from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "allow_postgres"
  }, var.default_tags)
}
module "db_postgres" {
  source = "terraform-aws-modules/rds/aws"
  # Info about module: https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/2.18.0

  name       = "postgresstrongdmdb"
  identifier = "postgres-10"

  # NOTE: Do NOT use 'user' as the value for 'username'
  username = "strongdmadmin"
  password = random_password.db_postgres_pw.result

  engine                  = "postgres"
  engine_version          = "10"
  major_engine_version    = "10"
  family                  = "postgres10"
  instance_class          = "db.t2.medium"
  allocated_storage       = 5
  storage_encrypted       = false
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0
  deletion_protection     = false

  # networking info
  port                   = "5432"
  vpc_security_group_ids = [aws_security_group.allow_postgres.id]
  subnet_ids             = data.aws_subnet_ids.public.ids
}
output name {
  value       = module.db_postgres.this_db_instance_address
  description = "postgres IP"
}

provider "postgresql" {
  host            = module.db_postgres.this_db_instance_address
  port            = module.db_postgres.this_db_instance_port
  database        = module.db_postgres.this_db_instance_name
  username        = module.db_postgres.this_db_instance_username
  password        = module.db_postgres.this_db_instance_password
  superuser       = false
  sslmode         = "require"
  connect_timeout = 15
}
resource "postgresql_database" "main_db" {
  name = "main_db"
}
resource "postgresql_role" "read_write" {
  name     = "db_admin"
  login    = true
  password = random_password.db_postgres_pw.result
  # reusing passwords is bad :) 
}
resource "postgresql_grant" "read_write" {
  database    = postgresql_database.main_db.name
  role        = postgresql_role.read_write.name
  schema      = "public"
  object_type = "database"
  privileges  = ["CREATE", "CONNECT", "TEMPORARY"]
}
resource "sdm_resource" "postgres_read_write" {
  postgres {
    name     = "postgres-example-admin"
    hostname = module.db_postgres.this_db_instance_address
    username = postgresql_role.read_write.name
    password = postgresql_role.read_write.password
    database = postgresql_database.main_db.name
    port     = 5432

    tags = var.default_tags
  }
}

resource "postgresql_role" "read_only" {
  name     = "db_read_only"
  login    = true
  password = random_password.db_postgres_pw.result
}
resource "postgresql_grant" "read_only" {
  database    = postgresql_database.main_db.name
  role        = postgresql_role.read_only.name
  schema      = "public"
  object_type = "database"
  privileges  = ["CONNECT"]
}
resource "sdm_resource" "postgres_read_only" {
  postgres {
    name     = "postgres-example-read-only"
    hostname = module.db_postgres.this_db_instance_address
    username = postgresql_role.read_only.name
    password = postgresql_role.read_only.password
    database = postgresql_database.main_db.name
    port     = 5432

    tags = var.default_tags
  }
}