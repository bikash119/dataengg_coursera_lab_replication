resource "aws_s3_bucket" "scripts" {
  bucket_prefix = "scripts-${data.aws_caller_identity.current.account_id}-"
}
resource "aws_s3_object" "glue_job_script" {
  bucket = aws_s3_bucket.scripts.id
  key    = "glue_job.py"
  source = "./assets/glue_job.py"

  etag = filemd5("./assets/glue_job.py")
}
