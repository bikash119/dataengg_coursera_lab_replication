resource "aws_glue_catalog_database" "lab1" {
  name = "MyCatalogDatabase"
  description = "AWS Glue metadata store for Lab 1"
}

resource "aws_glue_connection" "lab1" {
  name = "lab1_rds_connection"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${aws_db_instance.default.endpoint}/mysqldb"
    PASSWORD            = "foo"
    USERNAME            = "foobarbaz"
  }
    physical_connection_requirements {
    availability_zone      = aws_subnet.lab1.availability_zone
    security_group_id_list = [aws_security_group.mysql_sg.id]
    subnet_id              = aws_subnet.private_subnet_b.id
  }
}

resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.lab1.name
  name          = "lab1"
  role          = aws_iam_role.example.arn

  jdbc_target {
    connection_name = aws_glue_connection.lab1.name
    path            = "mysqldb/%"
  }
}

resource "aws_glue_job" "lab1" {
  name     = "lab1_etl_job"
  role_arn = aws_iam_role.example.arn

  command {
    script_location = "s3://${aws_s3_bucket.example.bucket}/etl.py"
  }
}