resource "aws_glue_catalog_database" "lab1" {
  name = "catalog_db"
  description = "AWS Glue metadata store for Lab 1"
}

resource "aws_glue_connection" "lab1" {
  name = "lab1_rds_connection"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://${aws_db_instance.default.endpoint}/classicmodels"
    PASSWORD            = "foobarbaz"
    USERNAME            = "foo"
  }
    physical_connection_requirements {
    availability_zone      = module.vpc.azs[0]
    security_group_id_list = [aws_security_group.mysql_sg.id]
    subnet_id              = module.vpc.private_subnets[0]
  }
}

resource "aws_glue_crawler" "s3_crawler" {
  name          = "analytics-db-crawler"
  database_name = aws_glue_catalog_database.lab1.name
  role          = aws_iam_role.glue_role.arn

  s3_target {
    path = "s3://${aws_s3_bucket.data_lake.bucket}/gold"
  }

  recrawl_policy {
    recrawl_behavior = "CRAWL_NEW_FOLDERS_ONLY"
  }

  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "LOG"
  }
}

resource "aws_glue_job" "lab1" {
  name     = "lab1_etl_job"
  role_arn = aws_iam_role.glue_role.arn
  glue_version = "4.0"
  connections  = [aws_glue_connection.lab1.name]

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.scripts.id}/${aws_s3_object.glue_job_script.id}"
    python_version  = 3
  }
  default_arguments = {
    "--enable-job-insights"               = "true"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--glue_connection"                   = aws_glue_connection.lab1.name
    "--glue_database"                     = aws_glue_catalog_database.lab1.name
    "--target_path"                       = "s3://${aws_s3_bucket.data_lake.bucket}/gold"
    "--continuous-log-logGroup"           = "/aws-glue/contin/jobs"
  }
  max_retries = 3
  timeout = 2

  number_of_workers = 2
  worker_type       = "G.1X"
}