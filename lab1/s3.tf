resource "aws_s3_bucket" "data_lake" {
  bucket_prefix = "datalake-${data.aws_caller_identity.current.account_id}-"
  force_destroy = true
}
resource "aws_s3_bucket" "scripts" {
  bucket_prefix = "scripts-${data.aws_caller_identity.current.account_id}-"
}
resource "aws_s3_object" "glue_job_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "glue_job.py"
  source = "./assets/glue_job.py"

  etag = filemd5("./assets/glue_job.py")
}

resource "aws_s3_object" "mysql_data_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "mysqlsampledatabase.sql"
  source = "./data/mysqlsampledatabase.sql"

  etag = filemd5("./data/mysqlsampledatabase.sql")
}
