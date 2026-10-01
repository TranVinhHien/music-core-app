package services

import (
	"bytes"
	"context"
	"github.com/TranVinhHien/music-core-app/music-core-api/internal/handlers/dto"
	"testing"
)

func TestUploadServiceUploadImageContract(t *testing.T) {
	s := &UploadService{}
	got, err := s.UploadImage(context.Background(), dto.UploadImageInput{File: bytes.NewReader([]byte("image")), ObjectKey: "x.png"})
	if err != nil {
		t.Fatal(err)
	}
	if got == nil {
		t.Fatal("nil response")
	}
}
