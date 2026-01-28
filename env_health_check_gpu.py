import torch
import sys


def check_health():
    try:
        if not torch.cuda.is_available():
            return False

        # Test a simple tensor operation on the 2060
        # This confirms the GPU isn't just "visible" but actually functional
        t = torch.randn(1024, 1024).cuda()
        _ = t @ t
        return True
    except Exception:
        return False


if __name__ == "__main__":
    if check_health():
        sys.exit(0)  # Healthy
    else:
        sys.exit(1)  # Unhealthy