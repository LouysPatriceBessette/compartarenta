package license

import (
	"context"
	"time"
)

// Verifier validates store purchases. Phase A uses client-reported status;
// Phase B implements Google Play; Phase C adds Apple.
type Verifier interface {
	Verify(ctx context.Context, platform string, receiptJSON []byte) (active bool, expiresAt *time.Time, err error)
}

// Stub accepts client-reported license status via the housing_plan_licenses
// table and does not validate receipt blobs yet.
type Stub struct{}

func (Stub) Verify(context.Context, string, []byte) (bool, *time.Time, error) {
	return false, nil, nil
}
