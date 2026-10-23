import os
import mimetypes
import uuid
from typing import Optional, Dict, Any
import boto3
from botocore.exceptions import ClientError

class StorageService:
    """
    Dịch vụ lưu trữ file: Upload audio và ảnh bìa lên AWS S3 (hoặc fallback cục bộ).
    """

    def __init__(self, config: Dict[str, Any]):
        self.config = config
        storage_cfg = config.get("storage", {})
        self.use_s3 = storage_cfg.get("use_s3", True)
        aws_cfg = storage_cfg.get("aws", {})

        self.region = aws_cfg.get("region", "ap-northeast-2")
        self.bucket = aws_cfg.get("bucket_name", "")
        self.access_key = aws_cfg.get("access_key_id", "")
        self.secret_key = aws_cfg.get("secret_access_key", "")

        self.s3_client = None
        if self.use_s3 and self.access_key and self.secret_key and self.bucket:
            try:
                self.s3_client = boto3.client(
                    "s3",
                    region_name=self.region,
                    aws_access_key_id=self.access_key,
                    aws_secret_access_key=self.secret_key
                )
            except Exception as e:
                print(f"[StorageService] Không thể khởi tạo S3 Client: {e}")

    def upload_file(self, local_path: str, folder: str = "tracks") -> Dict[str, Any]:
        """
        Upload một file (audio hoặc ảnh) lên Storage và trả về URL truy cập.
        """
        if not os.path.exists(local_path):
            raise FileNotFoundError(f"File không tồn tại: {local_path}")

        file_name = os.path.basename(local_path)
        ext = os.path.splitext(file_name)[1].lower()
        if ext == ".mp3":
            content_type = "audio/mpeg"
        elif ext in [".m4a", ".mp4"]:
            content_type = "audio/mp4"
        else:
            content_type, _ = mimetypes.guess_type(local_path)
            if not content_type:
                content_type = "application/octet-stream"

        # Assign unique object key to avoid collision
        unique_key = f"{folder}/{uuid.uuid4().hex[:8]}_{file_name}"

        if self.s3_client and self.bucket:
            try:
                print(f"[StorageService] Uploading file to S3 ({self.bucket}/{unique_key})...")
                self.s3_client.upload_file(
                    Filename=local_path,
                    Bucket=self.bucket,
                    Key=unique_key,
                    ExtraArgs={
                        "ContentType": content_type,
                    }
                )
                public_url = f"https://{self.bucket}.s3.{self.region}.amazonaws.com/{unique_key}"
                return {
                    "success": True,
                    "provider": "s3",
                    "url": public_url,
                    "key": unique_key,
                    "size_bytes": os.path.getsize(local_path),
                    "content_type": content_type
                }
            except ClientError as e:
                print(f"[StorageService] Failed to upload to S3: {e}. Falling back to local path.")

        # Local storage fallback
        local_url = f"file://{os.path.abspath(local_path)}"
        return {
            "success": True,
            "provider": "local",
            "url": local_url,
            "key": file_name,
            "size_bytes": os.path.getsize(local_path),
            "content_type": content_type
        }
