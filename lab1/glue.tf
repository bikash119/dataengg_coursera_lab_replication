resource "aws_glue_catalog_database" "lab1" {
  name = "catalog_db"
  description = "AWS Glue metadata store for Lab 1"
}

resource "aws_glue_connection" "lab1" {
  name = "lab1_rds_connection"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${aws_db_instance.default.endpoint}/mydb"
    PASSWORD            = "foobarbaz"
    USERNAME            = "foo"
  }
    physical_connection_requirements {
    availability_zone      = aws_subnet.private_subnet_a.availability_zone
    security_group_id_list = [aws_security_group.mysql_sg.id]
    subnet_id              = aws_subnet.private_subnet_a.id
  }
}

resource "aws_glue_crawler" "example" {
  database_name = aws_glue_catalog_database.lab1.name
  name          = "lab1"
  role          = aws_iam_role.glue_role.arn

  jdbc_target {
    connection_name = aws_glue_connection.lab1.name
    path            = "mysqldb/%"
  }
}

resource "aws_glue_job" "lab1" {
  name     = "lab1_etl_job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/${aws_s3_object.glue_job_script.id}"
    python_version  = 3
  }
}