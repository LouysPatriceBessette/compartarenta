package entitlement

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// Client calls the entitlement introspection API.
type Client struct {
	baseURL      string
	internalToken string
	httpClient   *http.Client
}

func NewClient(baseURL, internalToken string) *Client {
	return &Client{
		baseURL:       baseURL,
		internalToken: internalToken,
		httpClient:    &http.Client{Timeout: 5 * time.Second},
	}
}

type introspectRequest struct {
	Module                    string `json:"module"`
	PlanID                    string `json:"plan_id"`
	ParticipantInstallationID string `json:"participant_installation_id"`
	Operation                 string `json:"operation"`
	ExpenseID                 string `json:"expense_id"`
	RevisionID                string `json:"revision_id"`
	DecisionKind              string `json:"decision_kind"`
	EnvelopeKind              int    `json:"envelope_kind"`
}

type introspectResponse struct {
	Allow bool   `json:"allow"`
	Code  string `json:"code"`
}

// IntrospectEnvelope asks the entitlement service whether the gated
// envelope may be stored.
func (c *Client) IntrospectEnvelope(ctx context.Context, kind int, g *Gate) (allow bool, code string, err error) {
	body, err := json.Marshal(introspectRequest{
		Module:                    g.Module,
		PlanID:                    g.PlanID,
		ParticipantInstallationID: g.ParticipantInstallationID,
		Operation:                 g.Operation,
		ExpenseID:                 g.ExpenseID,
		RevisionID:                g.RevisionID,
		DecisionKind:              g.DecisionKind,
		EnvelopeKind:              kind,
	})
	if err != nil {
		return false, "", err
	}
	url := c.baseURL + "/v1/introspect/envelope"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return false, "", err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.internalToken != "" {
		req.Header.Set("Authorization", "Bearer "+c.internalToken)
	}
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return false, "entitlement_introspection_unavailable", err
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return false, "entitlement_introspection_unavailable", err
	}
	if resp.StatusCode != http.StatusOK {
		return false, "entitlement_introspection_rejected", fmt.Errorf("entitlement status %d: %s", resp.StatusCode, raw)
	}
	var out introspectResponse
	if err := json.Unmarshal(raw, &out); err != nil {
		return false, "entitlement_introspection_rejected", err
	}
	if !out.Allow {
		if out.Code == "" {
			out.Code = "entitlement_not_entitled"
		}
		return false, out.Code, nil
	}
	return true, out.Code, nil
}
