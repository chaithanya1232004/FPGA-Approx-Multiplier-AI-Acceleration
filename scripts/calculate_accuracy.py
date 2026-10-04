import os

SIM_OUTPUT_FILE = r"C:/Project/Approx_Booth_Multiplier_16bit/Approx_Booth_Multiplier_16bit.sim/sim_1/behav/xsim/out_result.txt"

if not os.path.exists(SIM_OUTPUT_FILE):
    print(f"[ERROR] Could not find file: {SIM_OUTPUT_FILE}")
    exit()

# Functions to convert unsigned integers to 2's complement signed integers
def to_signed_16(val):
    val = int(val)
    if val >= (1 << 15):
        val -= (1 << 16)
    return val

def to_signed_32(val):
    val = int(val)
    if val >= (1 << 31):
        val -= (1 << 32)
    return val

abs_error_distances = []
relative_errors = []

with open(SIM_OUTPUT_FILE, 'r') as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) == 3:
            # Convert raw numbers to signed 2's complement
            val_A = to_signed_16(parts[0])
            val_B = to_signed_16(parts[1])
            approx_p = to_signed_32(parts[2])
            
            # Exact mathematical signed product
            exact_p = val_A * val_B
            
            ed = abs(approx_p - exact_p)
            abs_error_distances.append(ed)
            
            if exact_p != 0:
                rel_err = ed / abs(exact_p)
                relative_errors.append(rel_err)
            else:
                relative_errors.append(0.0 if ed == 0 else 1.0)

N = len(abs_error_distances)
if N == 0:
    print("[ERROR] No valid data found in out_result.txt.")
    exit()

# Compute Metrics
mred = (sum(relative_errors) / N) * 100.0
D_max = (2**15)**2  # (-32768)^2 = 1,073,741,824
nmed = (sum(abs_error_distances) / N) / D_max
nmed_scaled = nmed * 10000.0
threshold = 0.02  # 2% threshold from the paper
count_within_threshold = sum(1 for err in relative_errors if err <= threshold)
pred = (count_within_threshold / N) * 100.0

print("\n" + "="*60)
print("              ACCURACY METRICS EVALUATION")
print("="*60)
print(f"Total Samples Evaluated : {N}")
print(f"MRED (%)                : {mred:.4f} %")
print(f"NMED (x 10^-4)          : {nmed_scaled:.4f}")
print(f"PRED (%)                : {pred:.2f} %")
print("="*60)
print("\nExpected values from Research Paper (Table VII, FABM f=18):")
print("MRED: 0.45 %  |  NMED: 0.62 x 10^-4  |  PRED: 97.66 %")
print("="*60)