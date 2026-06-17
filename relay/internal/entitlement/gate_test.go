package entitlement

import "testing"

func TestIsGatedKind(t *testing.T) {
	if !IsGatedKind(7) {
		t.Fatal("kind 7 should be gated")
	}
	if IsGatedKind(1) {
		t.Fatal("hello should not be gated")
	}
}

func TestValidateGate(t *testing.T) {
	code, ok := ValidateGate(7, nil)
	if ok || code != "entitlement_gate_required" {
		t.Fatalf("got %s %v", code, ok)
	}
	g := &Gate{Module: "housing", PlanID: "p1", ParticipantInstallationID: "inst-a"}
	code, ok = ValidateGate(7, g)
	if !ok || code != "" {
		t.Fatalf("got %s %v", code, ok)
	}
	if g.Operation != "housing_realized_expense_propose" {
		t.Fatalf("operation=%q", g.Operation)
	}
}
