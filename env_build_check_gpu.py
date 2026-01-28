import torch
import sys


def verify_gpu():
    print("--- RUNTIME HARDWARE CHECK ---")

    if not torch.cuda.is_available():
        print("❌ ERROR: No GPU detected by PyTorch!")
        print("Check if you used '--gpus all' or the GPU override file.")
        return False

    device_name = torch.cuda.get_device_name(0)
    vram = torch.cuda.get_device_properties(0).total_memory / 1e9

    print(f"✅ SUCCESS: Found GPU: {device_name}")
    print(f"📊 Total VRAM: {vram:.2f} GB")

    # 2060 specific warning
    if vram < 7:
        print("⚠️ NOTE: You have < 8GB VRAM. Use small batch sizes to avoid OOM.")

    print("------------------------------")
    return True


if __name__ == "__main__":
    if not verify_gpu():
        sys.exit(1)  # Exit with error code