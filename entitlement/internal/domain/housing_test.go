package domain

import (
	"testing"
	"time"

	"github.com/compartarenta/entitlement/internal/store"
)

func TestOperationFromKind(t *testing.T) {
	if operationFromKind(7) != "housing_realized_expense_propose" {
		t.Fatal()
	}
	if operationFromKind(99) != "" {
		t.Fatal()
	}
}

func TestIsNegotiationOperation(t *testing.T) {
	if !isNegotiationOperation("housing_proposal") {
		t.Fatal("proposal")
	}
	if !isNegotiationOperation("housing_proposal_response") {
		t.Fatal("response")
	}
	if isNegotiationOperation("housing_realized_expense_propose") {
		t.Fatal("expense propose is not negotiation")
	}
}

func TestIsPreActiveUse(t *testing.T) {
	if !isPreActiveUse(nil) {
		t.Fatal("nil plan")
	}
	started := time.Now()
	if isPreActiveUse(&store.Plan{ActiveUseStartedAt: &started}) {
		t.Fatal("active use started")
	}
	if !isPreActiveUse(&store.Plan{}) {
		t.Fatal("no active use yet")
	}
}

func TestIsMutatingOperation(t *testing.T) {
	if !isMutatingOperation("housing_realized_expense_propose") {
		t.Fatal()
	}
	if isMutatingOperation("read_only_query") {
		t.Fatal()
	}
}
