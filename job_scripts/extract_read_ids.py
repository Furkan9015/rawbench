import h5py
import os

fast5_dir = '/home/furkane/d10_dmelanogaster/fast5_10X'
output_file = '/home/furkane/d10_dmelanogaster/read_ids.txt'

def get_read_ids_from_fast5(fast5_file):
    read_ids = []
    with h5py.File(fast5_file, 'r') as f:
        for read in f.keys():
            if 'Raw' in f[read]:
                read_ids.append(read)
    return read_ids

read_ids = []
for root, _, files in os.walk(fast5_dir):
    for file in files:
        if file.endswith('.fast5'):
            filepath = os.path.join(root, file)
            try:
                ids = get_read_ids_from_fast5(filepath)
                read_ids.extend(ids)
            except Exception as e:
                print(f"Error reading {filepath}: {e}")

# Save read IDs to file
with open(output_file, 'w') as f:
    for rid in read_ids:
        f.write(rid + '\n')

print(f"Saved {len(read_ids)} read IDs to {output_file}")

