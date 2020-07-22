
# STEP1: セキュリティグループの作成

locals {
  rds_name = "${var.prefix}-rds-mysql"
}

# STEP2: セキュリティグループの作成

resource "aws_security_group" "this" {
  name        = local.rds_name
  description = local.rds_name

  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.rds_name
  }
}



resource "aws_security_group_rule" "mysql" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]
}



resource "aws_db_subnet_group" "this" {
  name        = local.rds_name
  description = local.rds_name
  subnet_ids  = [
    "${aws_subnet.private_1a.id}",
    "${aws_subnet.private_1c.id}",
    "${aws_subnet.private_1d.id}"
  ]
}



# RDS Cluster
# https://www.terraform.io/docs/providers/aws/r/rds_cluster.html
resource "aws_rds_cluster" "this" {
  cluster_identifier = local.rds_name

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = ["${aws_security_group.this.id}"]

  engine = "aurora-mysql"
  port   = "3306"

  database_name   = var.db_name
  master_username = var.db_user
  master_password = var.db_password

  # RDSインスタンス削除時のスナップショットの取得強制を無効化
  skip_final_snapshot = true

  # 使用する Parameter Group を指定
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
}



# RDS Cluster Instance
# https://www.terraform.io/docs/providers/aws/r/rds_cluster_instance.html
resource "aws_rds_cluster_instance" "this" {
  identifier         = local.rds_name
  cluster_identifier = aws_rds_cluster.this.id

  engine = "aurora-mysql"

  instance_class = "db.t3.small"
}



# RDS Cluster Parameter Group
# https://www.terraform.io/docs/providers/aws/r/rds_cluster_parameter_group.html
# 日本時間に変更 & 日本語対応のために文字コードを変更
resource "aws_rds_cluster_parameter_group" "this" {
  name   = local.rds_name
  family = "aurora-mysql5.7"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}



# terraform applyコマンド完了時にコンソールにエンドポイントを表示
# 【解説】もしエンドポイントも機密情報として扱うのであれば
# ここで表示されたエンドポイントをパラメータストアに格納すればよい。
# 今回は紹介のために使用。
output "rds_endpoint" {
  value = aws_rds_cluster.this.endpoint
}

