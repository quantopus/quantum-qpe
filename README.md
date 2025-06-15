# Quantum QPE

Quantum Phase Estimation (QPE) algorithm implementation using PennyLane.

## Overview

QPE is a fundamental quantum algorithm for estimating eigenvalues of unitary operators. This implementation provides:

- PennyLane-based quantum circuit simulation
- Flexible unitary operator configurations
- Typed parameters with Pydantic validation
- Configurable precision and measurement strategies
- Integration with Quantopus ecosystem

## Installation

```bash
make dev-install
```

## Usage

```python
from quantum_qpe import QPEAlgorithm, QPEParams

# Create QPE instance
qpe = QPEAlgorithm()

# Set parameters for phase estimation
params = QPEParams(
    angle=0.25,  # Phase to estimate (in units of 2π)
    unitary="rotation",  # Type of unitary operator
    precision=4,  # Number of ancilla qubits
    measurements=1000
)

# Execute algorithm
result = qpe.execute(params)
print(f"Estimated phase: {result.estimated_phase}")
print(f"Confidence: {result.confidence}")
```

## Demo

```bash
make demo
```

## Development

```bash
make test     # Run tests
make lint     # Check code quality
make format   # Format code
```

Part of the [Quantopus](https://github.com/quantopus) quantum computing ecosystem.
