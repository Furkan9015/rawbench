## H. sapiens

cd hsapiens
aws s3 cp s3://ont-open-data/giab_2023.05/flowcells/hg002/20230424_1302_3H_PAO89685_2264ba8c/pod5_pass/2264ba8c_afee3a87_1.0_275.pod5 ./ --no-sign-request
aws s3 cp s3://ont-open-data/giab_2023.05/flowcells/hg002/20230424_1302_3H_PAO89685_2264ba8c/pod5_pass/2264ba8c_afee3a87_26.0_418.pod5 ./ --no-sign-request
aws s3 cp s3://ont-open-data/giab_2023.05/flowcells/hg002/20230424_1302_3H_PAO89685_2264ba8c/pod5_pass/2264ba8c_afee3a87_32.0_225.pod5 ./ --no-sign-request
aws s3 cp s3://ont-open-data/giab_2023.05/flowcells/hg002/20230424_1302_3H_PAO89685_2264ba8c/pod5_pass/2264ba8c_afee3a87_9.0_207.pod5 ./ --no-sign-request


## E. coli

cd ..

# pip install pod5
# make sure fast5 files are downloaded
pod5 convert fast5 ../fast5/ecoli/*.fast5 --output ../pod5/ecoli/ --one-to-one ./ecoli/

## D. melanogaster

# make sure fast5 files are downloaded
pod5 convert fast5 ../fast5/dmelanogaster/*.fast5 --output ../pod5/dmelanogaster/ --one-to-one ./dmelanogaster/
