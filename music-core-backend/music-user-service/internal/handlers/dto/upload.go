package dto

import "io"

type UploadImageInput struct {
	File      io.ReadSeeker
	ObjectKey string
}

type UploadImageResponse struct {
	URL string `json:"url"`
}
