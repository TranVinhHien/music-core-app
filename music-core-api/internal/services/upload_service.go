package services

import (
	"context"

	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
)

// "github.com/aws/aws-sdk-go-v2/aws"
// awsconfig "github.com/aws/aws-sdk-go-v2/config"
// "github.com/aws/aws-sdk-go-v2/credentials"
// "github.com/aws/aws-sdk-go-v2/service/s3"

type UploadService struct {
	// s3Client   *s3.Client
	bucketName string
	region     string
}

func NewUploadService() (*UploadService, error) {
	// 	ctx := context.Background()
	// 	cfg, err := awsconfig.LoadDefaultConfig(ctx,
	// 		awsconfig.WithRegion(config.App.AWS.Region),
	// 		awsconfig.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
	// 			config.App.AWS.AccessKeyID,
	// 			config.App.AWS.SecretAccessKey,
	// 			"",
	// 		)),
	// 	)
	// 	if err != nil {
	// 		return nil, fmt.Errorf("unable to load SDK config: %w", err)
	// 	}

	// 	client := s3.NewFromConfig(cfg)
	// 	return &UploadService{
	// 		s3Client:   client,
	// 		bucketName: config.App.AWS.BucketName,
	// 		region:     config.App.AWS.Region,
	// 	}, nil
	return nil, nil
}

func (s *UploadService) UploadImage(ctx context.Context, input dto.UploadImageInput) (*dto.UploadImageResponse, error) {
	// 	// 1. Detect content type by reading the first 512 bytes
	// 	buffer := make([]byte, 512)
	// 	_, err := file.Read(buffer)
	// 	if err != nil && err != io.EOF {
	// 		return "", fmt.Errorf("failed to read file buffer: %w", err)
	// 	}

	// 	// Seek back to start
	// 	_, err = file.Seek(0, io.SeekStart)
	// 	if err != nil {
	// 		return "", fmt.Errorf("failed to seek file: %w", err)
	// 	}

	// 	contentType := http.DetectContentType(buffer)

	// 	// 2. Upload to S3
	// 	_, err = s.s3Client.PutObject(ctx, &s3.PutObjectInput{
	// 		Bucket:             aws.String(s.bucketName),
	// 		Key:                aws.String(objectKey),
	// 		Body:               file,
	// 		ContentType:        aws.String(contentType),
	// 		ContentDisposition: aws.String("inline"),
	// 	})
	// 	if err != nil {
	// 		return "", fmt.Errorf("s3 upload failed: %w", err)
	// 	}

	// 	// 3. Generate static URL
	// 	staticURL := fmt.Sprintf("https://%s.s3.%s.amazonaws.com/%s", s.bucketName, s.region, objectKey)
	return &dto.UploadImageResponse{}, nil
}
