package domain

import "testing"

func TestOperationFromKind(t *testing.T) {
	if operationFromKind(7) != "housing_realized_expense_propose" {
		t.Fatal()
	}
	if operationFromKind(99) != "" {
		t.Fatal()
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
