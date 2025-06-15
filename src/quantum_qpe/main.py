"""QPE (Quantum Phase Estimation) Algorithm Implementation using PennyLane."""

import logging
from typing import Literal

import numpy as np
import pennylane as qml
from pydantic import Field, confloat, conint
from quantum_interfaces import AlgorithmParams, AlgorithmResult, BaseAlgorithm, ValidationError

logger = logging.getLogger(__name__)


class QPEParams(AlgorithmParams):
    """Parameters for Quantum Phase Estimation algorithm."""
    
    unitary: Literal["rotation", "phase", "z"] = Field(
        default="rotation",
        description="Type of unitary operation"
    )
    angle: confloat(ge=0.0, le=1.0) = Field(
        ...,
        description="Phase angle to estimate (normalized to [0,1])"
    )
    precision: conint(ge=1, le=10) = Field(
        default=4,
        description="Number of precision qubits (1-10)"
    )


class QPEResult(AlgorithmResult):
    """Result from Quantum Phase Estimation algorithm."""
    
    estimated_phase: float = Field(..., description="Estimated phase value")
    true_phase: float = Field(..., description="True phase value for comparison")
    phase_error: float = Field(..., description="Absolute error in phase estimation")
    measurement_probability: float = Field(..., description="Probability of the measurement outcome")
    measured_value: int = Field(..., description="Raw measured integer value")
    precision_bits: int = Field(..., description="Number of precision bits used")
    unitary_type: str = Field(..., description="Type of unitary operation used")


class QPEAlgorithm(BaseAlgorithm[QPEParams, QPEResult]):
    """Quantum Phase Estimation algorithm implementation."""
    
    def validate_params(self, params: QPEParams) -> None:
        """
        Validate QPE parameters.
        Pydantic handles basic validation, this is for additional logic.
        """
        # Pydantic already validates angle range and precision range
        pass
    
    def execute(self, params: QPEParams) -> QPEResult:
        """
        Execute QPE algorithm.
        
        Args:
            params: QPE parameters
        
        Returns:
            QPE results with estimated phase and metrics
        """
        try:
            logger.info(f"Starting QPE with params: {params}")
            
            # Create quantum device
            n_qubits = params.precision + 1  # precision qubits + 1 eigenstate qubit
            dev = qml.device('default.qubit', wires=n_qubits)
            
            def unitary_operator(wire):
                """Define the unitary operator based on type."""
                if params.unitary == 'rotation':
                    qml.RY(2 * np.pi * params.angle, wires=wire)
                elif params.unitary == 'phase':
                    qml.PhaseShift(2 * np.pi * params.angle, wires=wire)
                else:  # 'z'
                    qml.RZ(2 * np.pi * params.angle, wires=wire)
            
            def controlled_unitary(control_wire, target_wire, power):
                """Apply controlled unitary raised to given power."""
                for _ in range(2**power):
                    qml.ctrl(unitary_operator, control=control_wire)(target_wire)
            
            def qpe_circuit():
                """QPE quantum circuit."""
                # Initialize eigenstate qubit
                qml.PauliX(wires=params.precision)
                
                # Create superposition in precision qubits
                for i in range(params.precision):
                    qml.Hadamard(wires=i)
                
                # Apply controlled unitaries
                for i in range(params.precision):
                    controlled_unitary(i, params.precision, i)
                
                # Apply inverse QFT
                qml.adjoint(qml.QFT)(wires=range(params.precision))
            
            @qml.qnode(dev, interface='autograd')
            def qpe_measurement():
                """QPE measurement circuit."""
                qpe_circuit()
                return qml.probs(wires=range(params.precision))
            
            # Execute the circuit
            probabilities = qpe_measurement()
            
            # Find the most probable measurement outcome
            measured_value = np.argmax(probabilities)
            estimated_phase = measured_value / (2**params.precision)
            
            # Calculate confidence and error
            max_probability = float(np.max(probabilities))
            phase_error = abs(estimated_phase - params.angle)
            
            result = QPEResult(
                estimated_phase=float(estimated_phase),
                true_phase=float(params.angle),
                phase_error=float(phase_error),
                measurement_probability=max_probability,
                measured_value=int(measured_value),
                precision_bits=params.precision,
                unitary_type=params.unitary,
                meta={
                    "algorithm": "QPE",
                    "provider": "pennylane",
                    "device": "default.qubit",
                    "n_qubits": n_qubits
                }
            )
            
            logger.info(f"QPE completed successfully: phase={estimated_phase:.4f}, error={phase_error:.4f}")
            return result
            
        except Exception as e:
            logger.error(f"QPE execution failed: {str(e)}")
            raise ValidationError(f"QPE execution failed: {str(e)}") from e 