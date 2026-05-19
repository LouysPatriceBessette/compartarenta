package push

import (
	"bytes"
	"context"
	"crypto/ecdsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// APNsWake sends a silent push with custom fields alongside aps.
type APNsWake struct {
	HTTPClient *http.Client
	Host       string // api.development.push.apple.com or api.push.apple.com
	KeyID      string
	TeamID     string
	BundleID   string
	PrivateKey *ecdsa.PrivateKey
	// GenericAlertBody when non-empty adds aps.alert string (degraded mode).
	GenericAlertBody string
}

// NewAPNsFromKeyFile loads a .p8 auth key and returns a configured sender.
func NewAPNsFromKeyFile(path, keyID, teamID, bundleID, environment string, genericAlert string) (*APNsWake, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read APNs key: %w", err)
	}
	block, _ := pem.Decode(raw)
	if block == nil {
		return nil, fmt.Errorf("apns key: no PEM block")
	}
	keyAny, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("apns key parse: %w", err)
	}
	ecKey, ok := keyAny.(*ecdsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("apns key: want ECDSA private key")
	}
	host := "https://api.push.apple.com"
	if strings.EqualFold(strings.TrimSpace(environment), "sandbox") ||
		strings.EqualFold(strings.TrimSpace(environment), "development") {
		host = "https://api.development.push.apple.com"
	}
	return &APNsWake{
		HTTPClient:       &http.Client{Timeout: 20 * time.Second},
		Host:             host,
		KeyID:            keyID,
		TeamID:           teamID,
		BundleID:         bundleID,
		PrivateKey:       ecKey,
		GenericAlertBody: strings.TrimSpace(genericAlert),
	}, nil
}

func (a *APNsWake) bearerToken() (string, error) {
	if a == nil || a.PrivateKey == nil {
		return "", fmt.Errorf("apns sender not configured")
	}
	now := time.Now().Unix()
	tok := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
		"iss": a.TeamID,
		"iat": now,
	})
	tok.Header["kid"] = a.KeyID
	return tok.SignedString(a.PrivateKey)
}

type apnsPayload struct {
	Aps        map[string]any `json:"aps"`
	V          int             `json:"v"`
	Kind       string          `json:"kind"`
	Recipient  string          `json:"recipient"`
}

// SendWake delivers a data-style wake to one device token (hex or base64
// as provided by the client; Apple expects hex device token in URL path).
func (a *APNsWake) SendWake(ctx context.Context, deviceToken string, recipientB64 string) error {
	if a == nil || a.PrivateKey == nil {
		return fmt.Errorf("apns sender not configured")
	}
	auth, err := a.bearerToken()
	if err != nil {
		return err
	}
	aps := map[string]any{
		"content-available": 1,
	}
	if a.GenericAlertBody != "" {
		aps["alert"] = a.GenericAlertBody
	}
	body := apnsPayload{
		Aps:       aps,
		V:         1,
		Kind:      "wake_for_inbox",
		Recipient: recipientB64,
	}
	raw, err := json.Marshal(body)
	if err != nil {
		return err
	}
	path := fmt.Sprintf("%s/3/device/%s", a.Host, deviceToken)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, path, bytes.NewReader(raw))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+auth)
	req.Header.Set("apns-topic", a.BundleID)
	req.Header.Set("apns-push-type", "background")
	req.Header.Set("apns-priority", "5")
	req.Header.Set("content-type", "application/json")

	resp, err := a.HTTPClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 64<<10))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("apns http %d: %s", resp.StatusCode, strings.TrimSpace(string(respBody)))
	}
	return nil
}

// SendWakeClassify maps 410 Gone and BadDeviceToken to [PermanentTokenError].
func (a *APNsWake) SendWakeClassify(ctx context.Context, deviceToken string, recipientB64 string) error {
	err := a.SendWake(ctx, deviceToken, recipientB64)
	if err == nil {
		return nil
	}
	s := strings.ToLower(err.Error())
	if strings.Contains(s, "410") ||
		strings.Contains(s, "baddevicetoken") ||
		strings.Contains(s, "unregistered") {
		return &PermanentTokenError{Detail: err.Error()}
	}
	return err
}
