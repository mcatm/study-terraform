resource "aws_instance" "sandbox" {
  count         = 1
  ami           = "ami-785c491f"
  instance_type = "t2.micro"
  subnet_id = "subnet-003a16599c355cf5b" # 俺がデフォルトサブネット消しちゃったから指定が必須になってしまった…。試すときは、この記述削除してください

  tags = {
    Name = "${var.prefix}-ec2-${count.index + 1}"
  }
}