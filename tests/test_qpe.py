import pytest
from quantum_qpe.main import QPEAlgorithm, QPEParams

def test_qpe_execution():
    """Tests that the QPE mock algorithm executes correctly."""
    params = QPEParams(unitary="rotation", angle=0.5, precision=3)
    algorithm = QPEAlgorithm()
    result = algorithm.execute(params)
    
    assert result.estimated_phase == 0.25
    assert result.meta["provider"] == "pennylane"

def test_qpe_validation_error():
    """Tests that the QPE algorithm raises a validation error for invalid parameters."""
    with pytest.raises(Exception):
        QPEParams(unitary="invalid", angle=0.5, precision=3)