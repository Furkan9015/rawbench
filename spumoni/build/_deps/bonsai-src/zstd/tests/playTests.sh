#!/bin/sh

set -e

die() {
    println "$@" 1>&2
    exit 1
}

datagen() {
    "$DATAGEN_BIN" "$@"
}

zstd() {
    if [ -z "$EXEC_PREFIX" ]; then
        "$ZSTD_BIN" "$@"
    else
        "$EXEC_PREFIX" "$ZSTD_BIN" "$@"
    fi
}

sudoZstd() {
    if [ -z "$EXEC_PREFIX" ]; then
        sudo "$ZSTD_BIN" "$@"
    else
        sudo "$EXEC_PREFIX" "$ZSTD_BIN" "$@"
    fi
}

roundTripTest() {
    if [ -n "$3" ]; then
        cLevel="$3"
        proba="$2"
    else
        cLevel="$2"
        proba=""
    fi
    if [ -n "$4" ]; then
        dLevel="$4"
    else
        dLevel="$cLevel"
    fi

    rm -f tmp1 tmp2
    println "roundTripTest: datagen $1 $proba | zstd -v$cLevel | zstd -d$dLevel"
    datagen $1 $proba | $MD5SUM > tmp1
    datagen $1 $proba | zstd --ultra -v$cLevel | zstd -d$dLevel  | $MD5SUM > tmp2
    $DIFF -q tmp1 tmp2
}

fileRoundTripTest() {
    if [ -n "$3" ]; then
        local_c="$3"
        local_p="$2"
    else
        local_c="$2"
        local_p=""
    fi
    if [ -n "$4" ]; then
        local_d="$4"
    else
        local_d="$local_c"
    fi

    rm -f tmp.zst tmp.md5.1 tmp.md5.2
    println "fileRoundTripTest: datagen $1 $local_p > tmp && zstd -v$local_c -c tmp | zstd -d$local_d"
    datagen $1 $local_p > tmp
    < tmp $MD5SUM > tmp.md5.1
    zstd --ultra -v$local_c -c tmp | zstd -d$local_d | $MD5SUM > tmp.md5.2
    $DIFF -q tmp.md5.1 tmp.md5.2
}

truncateLastByte() {
    dd bs=1 count=$(($(wc -c < "$1") - 1)) if="$1"
}

println() {
    printf '%b\n' "${*}"
}

if [ -z "${size}" ]; then
    size=
else
    size=${size}
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PRGDIR="$SCRIPT_DIR/../programs"
TESTDIR="$SCRIPT_DIR/../tests"
UNAME=$(uname)
ZSTDGREP="$PRGDIR/zstdgrep"

detectedTerminal=false
if [ -t 0 ] && [ -t 1 ]
then
    detectedTerminal=true
fi
isTerminal=${isTerminal:-$detectedTerminal}

isWindows=false
INTOVOID="/dev/null"
case "$UNAME" in
  GNU) DEVDEVICE="/dev/random" ;;
  *) DEVDEVICE="/dev/zero" ;;
esac
case "$OS" in
  Windows*)
    isWindows=true
    INTOVOID="NUL"
    DEVDEVICE="NUL"
    ;;
esac

case "$UNAME" in
  Darwin) MD5SUM="md5 -r" ;;
  FreeBSD) MD5SUM="gmd5sum" ;;
  OpenBSD) MD5SUM="md5" ;;
  *) MD5SUM="md5sum" ;;
esac

MTIME="stat -c %Y"
case "$UNAME" in
    Darwin | FreeBSD | OpenBSD) MTIME="stat -f %m" ;;
esac

DIFF="diff"
case "$UNAME" in
  SunOS) DIFF="gdiff" ;;
esac


# check if ZSTD_BIN is defined. if not, use the default value
if [ -z "${ZSTD_BIN}" ]; then
  println "\nZSTD_BIN is not set. Using the default value..."
  ZSTD_BIN="$PRGDIR/zstd"
fi

# check if DATAGEN_BIN is defined. if not, use the default value
if [ -z "${DATAGEN_BIN}" ]; then
  println "\nDATAGEN_BIN is not set. Using the default value..."
  DATAGEN_BIN="$TESTDIR/datagen"
fi

ZSTD_BIN="$EXE_PREFIX$ZSTD_BIN"

# assertions
[ -n "$ZSTD_BIN" ] || die "zstd not found at $ZSTD_BIN! \n Please define ZSTD_BIN pointing to the zstd binary. You might also consider rebuilding zstd follwing the instructions in README.md"
[ -n "$DATAGEN_BIN" ] || die "datagen not found at $DATAGEN_BIN! \n Please define DATAGEN_BIN pointing to the datagen binary. You might also consider rebuilding zstd tests following the instructions in README.md. "
println "\nStarting playTests.sh isWindows=$isWindows EXE_PREFIX='$EXE_PREFIX' ZSTD_BIN='$ZSTD_BIN' DATAGEN_BIN='$DATAGEN_BIN'"

if echo hello | zstd -v -T2 2>&1 > $INTOVOID | grep -q 'multi-threading is disabled'
then
    hasMT=""
else
    hasMT="true"
fi



println "\n===>  simple tests "

datagen > tmp
println "test : basic compression "
zstd -f tmp                      # trivial compression case, creates tmp.zst
println "test : basic decompression"
zstd -df tmp.zst                 # trivial decompression case (overwrites tmp)
println "test : too large compression level => auto-fix"
zstd -99 -f tmp  # too large compression level, automatic sized down
zstd -5000000000 -f tmp && die "too large numeric value : must fail"
println "test : --fast aka negative compression levels"
zstd --fast -f tmp  # == -1
zstd --fast=3 -f tmp  # == -3
zstd --fast=200000 -f tmp  # too low compression level, automatic fixed
zstd --fast=5000000000 -f tmp && die "too large numeric value : must fail"
zstd -c --fast=0 tmp > $INTOVOID && die "--fast must not accept value 0"
println "test : too large numeric argument"
zstd --fast=9999999999 -f tmp  && die "should have refused numeric value"
println "test : set compression level with environment variable ZSTD_CLEVEL"
ZSTD_CLEVEL=12  zstd -f tmp # positive compression level
ZSTD_CLEVEL=-12 zstd -f tmp # negative compression level
ZSTD_CLEVEL=+12 zstd -f tmp # valid: verbose '+' sign
ZSTD_CLEVEL=''  zstd -f tmp # empty env var, warn and revert to default setting
ZSTD_CLEVEL=-   zstd -f tmp # malformed env var, warn and revert to default setting
ZSTD_CLEVEL=a   zstd -f tmp # malformed env var, warn and revert to default setting
ZSTD_CLEVEL=+a  zstd -f tmp # malformed env var, warn and revert to default setting
ZSTD_CLEVEL=3a7 zstd -f tmp # malformed env var, warn and revert to default setting
ZSTD_CLEVEL=50000000000 zstd -f tmp # numeric value too large, warn and revert to default setting
println "test : override ZSTD_CLEVEL with command line option"
ZSTD_CLEVEL=12  zstd --fast=3 -f tmp # overridden by command line option
println "test : compress to stdout"
zstd tmp -c > tmpCompressed
zstd tmp --stdout > tmpCompressed       # long command format
println "test : compress to named file"
rm tmpCompressed
zstd tmp -o tmpCompressed
test -f tmpCompressed   # file must be created
println "test : force write, correct order"
zstd tmp -fo tmpCompressed
println "test : forgotten argument"
cp tmp tmp2
zstd tmp2 -fo && die "-o must be followed by filename "
println "test : implied stdout when input is stdin"
println bob | zstd | zstd -d
if [ "$isTerminal" = true ]; then
println "test : compressed data to terminal"
println bob | zstd && die "should have refused : compressed data to terminal"
println "test : compressed data from terminal (a hang here is a test fail, zstd is wrongly waiting on data from terminal)"
zstd -d > $INTOVOID && die "should have refused : compressed data from terminal"
fi
println "test : null-length file roundtrip"
println -n '' | zstd - --stdout | zstd -d --stdout
println "test : ensure small file doesn't add 3-bytes null block"
datagen -g1 > tmp1
zstd tmp1 -c | wc -c | grep "14"
zstd < tmp1  | wc -c | grep "14"
println "test : decompress file with wrong suffix (must fail)"
zstd -d tmpCompressed && die "wrong suffix error not detected!"
zstd -df tmp && die "should have refused : wrong extension"
println "test : decompress into stdout"
zstd -d tmpCompressed -c > tmpResult    # decompression using stdout
zstd --decompress tmpCompressed -c > tmpResult
zstd --decompress tmpCompressed --stdout > tmpResult
println "test : decompress from stdin into stdout"
zstd -dc   < tmp.zst > $INTOVOID   # combine decompression, stdin & stdout
zstd -dc - < tmp.zst > $INTOVOID
zstd -d    < tmp.zst > $INTOVOID   # implicit stdout when stdin is used
zstd -d  - < tmp.zst > $INTOVOID
println "test : impose memory limitation (must fail)"
zstd -d -f tmp.zst -M2K -c > $INTOVOID && die "decompression needs more memory than allowed"
zstd -d -f tmp.zst --memlimit=2K -c > $INTOVOID && die "decompression needs more memory than allowed"  # long command
zstd -d -f tmp.zst --memory=2K -c > $INTOVOID && die "decompression needs more memory than allowed"  # long command
zstd -d -f tmp.zst --memlimit-decompress=2K -c > $INTOVOID && die "decompression needs more memory than allowed"  # long command
println "test : overwrite protection"
zstd -q tmp && die "overwrite check failed!"
println "test : force overwrite"
zstd -q -f tmp
zstd -q --force tmp
println "test : overwrite readonly file"
rm -f tmpro tmpro.zst
println foo > tmpro.zst
println foo > tmpro
chmod 400 tmpro.zst
zstd -q tmpro && die "should have refused to overwrite read-only file"
zstd -q -f tmpro
println "test: --no-progress flag"
zstd tmpro -c --no-progress | zstd -d -f -o "$INTOVOID" --no-progress
zstd tmpro -cv --no-progress | zstd -dv -f -o "$INTOVOID" --no-progress
rm -f tmpro tmpro.zst
println "test: overwrite input file (must fail)"
zstd tmp -fo tmp && die "zstd compression overwrote the input file"
zstd tmp.zst -dfo tmp.zst && die "zstd decompression overwrote the input file"
println "test: detect that input file does not exist"
zstd nothere && die "zstd hasn't detected that input file does not exist"
println "test: --[no-]compress-literals"
zstd tmp -c --no-compress-literals -1       | zstd -t
zstd tmp -c --no-compress-literals --fast=1 | zstd -t
zstd tmp -c --no-compress-literals -19      | zstd -t
zstd tmp -c --compress-literals    -1       | zstd -t
zstd tmp -c --compress-literals    --fast=1 | zstd -t
zstd tmp -c --compress-literals    -19      | zstd -t
zstd -b --fast=1 -i0e1 tmp --compress-literals
zstd -b --fast=1 -i0e1 tmp --no-compress-literals
println "test: --no-check for decompression"
zstd -f tmp -o tmp_corrupt.zst --check
zstd -f tmp -o tmp.zst --no-check
printf '\xDE\xAD\xBE\xEF' | dd of=tmp_corrupt.zst bs=1 seek=$(($(wc -c < "tmp_corrupt.zst") - 4)) count=4 conv=notrunc # corrupt checksum in tmp
zstd -d -f tmp_corrupt.zst --no-check
zstd -d -f tmp_corrupt.zst --check --no-check # final flag overrides
zstd -d -f tmp.zst --no-check

println "\n===> zstdgrep tests"
ln -sf "$ZSTD_BIN" zstdcat
rm -f tmp_grep
echo "1234" > tmp_grep
zstd -f tmp_grep
lines=$(ZCAT=./zstdcat $ZSTDGREP 2>&1 "1234" tmp_grep tmp_grep.zst | wc -l)
test 2 -eq $lines
ZCAT=./zstdcat $ZSTDGREP 2>&1 "1234" tmp_grep_bad.zst && die "Should have failed"
ZCAT=./zstdcat $ZSTDGREP 2>&1 "1234" tmp_grep_bad.zst | grep "No such file or directory" || true
rm -f tmp_grep*

println "\n===>  --exclude-compressed flag"
rm -rf precompressedFilterTestDir
mkdir -p precompressedFilterTestDir
datagen $size > precompressedFilterTestDir/input.5
datagen $size > precompressedFilterTestDir/input.6
zstd --exclude-compressed --long --rm -r precompressedFilterTestDir
datagen $size > precompressedFilterTestDir/input.7
datagen $size > precompressedFilterTestDir/input.8
zstd --exclude-compressed --long --rm -r precompressedFilterTestDir
test ! -f precompressedFilterTestDir/input.5.zst.zst
test ! -f precompressedFilterTestDir/input.6.zst.zst
file1timestamp=`$MTIME precompressedFilterTestDir/input.5.zst`
file2timestamp=`$MTIME precompressedFilterTestDir/input.7.zst`
if [ $file2timestamp -ge $file1timestamp ]; then
  println "Test is successful. input.5.zst is precompressed and therefore not compressed/modified again."
else
  println "Test is not successful"
fi
# File Extension check.
datagen $size > precompressedFilterTestDir/input.zstbar
zstd --exclude-compressed --long --rm -r precompressedFilterTestDir
# zstd should compress input.zstbar
test -f precompressedFilterTestDir/input.zstbar.zst
# Check without the --exclude-compressed flag
zstd --long --rm -r precompressedFilterTestDir
# Files should get compressed again without the --exclude-compressed flag.
test -f precompressedFilterTestDir/input.5.zst.zst
test -f precompressedFilterTestDir/input.6.zst.zst
println "Test completed"


println "\n===>  recursive mode test "
# combination of -r with empty list of input file
zstd -c -r < tmp > tmp.zst


println "\n===>  file removal"
zstd -f --rm tmp
test ! -f tmp  # tmp should no longer be present
zstd -f -d --rm tmp.zst
test ! -f tmp.zst   # tmp.zst should no longer be present
println "test : should quietly not remove non-regular file"
println hello > tmp
zstd tmp -f -o "$DEVDEVICE" 2>tmplog > "$INTOVOID"
grep -v "Refusing to remove non-regular file" tmplog
rm -f tmplog
zstd tmp -f -o "$INTOVOID" 2>&1 | grep -v "Refusing to remove non-regular file"
println "test : --rm on stdin"
println a | zstd --rm > $INTOVOID   # --rm should remain silent
rm tmp
zstd -f tmp && die "tmp not present : should have failed"
test ! -f tmp.zst  # tmp.zst should not be created
println "test : -d -f do not delete destination when source is not present"
touch tmp    # create destination file
zstd -d -f tmp.zst && die "attempt to decompress a non existing file"
test -f tmp  # destination file should still be present
println "test : -f do not delete destination when source is not present"
rm tmp         # erase source file
touch tmp.zst  # create destination file
zstd -f tmp && die "attempt to compress a non existing file"
test -f tmp.zst  # destination file should still be present
rm -rf tmp*  # may also erase tmp* directory from previous failed run


println "\n===>  decompression only tests "
# the following test verifies that the decoder is compatible with RLE as first block
# older versions of zstd cli are not able to decode such corner case.
# As a consequence, the zstd cli do not generate them, to maintain compatibility with older versions.
dd bs=1048576 count=1 if=/dev/zero of=tmp
zstd -d -o tmp1 "$TESTDIR/golden-decompression/rle-first-block.zst"
$DIFF -s tmp1 tmp
rm tmp*


println "\n===>  compress multiple files"
println hello > tmp1
println world > tmp2
zstd tmp1 tmp2 -o "$INTOVOID" -f
zstd tmp1 tmp2 -c | zstd -t
zstd tmp1 tmp2 -o tmp.zst
test ! -f tmp1.zst
test ! -f tmp2.zst
zstd tmp1 tmp2
zstd -t tmp1.zst tmp2.zst
zstd -dc tmp1.zst tmp2.zst
zstd tmp1.zst tmp2.zst -o "$INTOVOID" -f
zstd -d tmp1.zst tmp2.zst -o tmp
touch tmpexists
zstd tmp1 tmp2 -f -o tmpexists
zstd tmp1 tmp2 -o tmpexists && die "should have refused to overwrite"
# Bug: PR #972
if [ "$?" -eq 139 ]; then
  die "should not have segfaulted"
fi
println "\n===>  multiple files and shell completion "
datagen -s1        > tmp1 2> $INTOVOID
datagen -s2 -g100K > tmp2 2> $INTOVOID
datagen -s3 -g1M   > tmp3 2> $INTOVOID
println "compress tmp* : "
zstd -f tmp*
test -f tmp1.zst
test -f tmp2.zst
test -f tmp3.zst
rm tmp1 tmp2 tmp3
println "decompress tmp* : "
zstd -df ./*.zst
test -f tmp1
test -f tmp2
test -f tmp3
println "compress tmp* into stdout > tmpall : "
zstd -c tmp1 tmp2 tmp3 > tmpall
test -f tmpall  # should check size of tmpall (should be tmp1.zst + tmp2.zst + tmp3.zst)
println "decompress tmpall* into stdout > tmpdec : "
cp tmpall tmpall2
zstd -dc tmpall* > tmpdec
test -f tmpdec  # should check size of tmpdec (should be 2*(tmp1 + tmp2 + tmp3))
println "compress multiple files including a missing one (notHere) : "
zstd -f tmp1 notHere tmp2 && die "missing file not detected!"
rm tmp*


if [ "$isWindows" = false ] ; then
    println "\n===>  zstd fifo named pipe test "
    echo "Hello World!" > tmp_original
    mkfifo tmp_named_pipe
    # note : fifo test doesn't work in combination with `dd` or `cat`
    echo "Hello World!" > tmp_named_pipe &
    zstd tmp_named_pipe -o tmp_compressed
    zstd -d -o tmp_decompressed tmp_compressed
    $DIFF -s tmp_original tmp_decompressed
    rm -rf tmp*
fi


if [ -n "$DEVNULLRIGHTS" ] ; then
    # these tests requires sudo rights, which is uncommon.
    # they are only triggered if DEVNULLRIGHTS macro is defined.
    println "\n===> checking /dev/null permissions are unaltered "
    datagen > tmp
    sudoZstd tmp -o $INTOVOID   # sudo rights could modify /dev/null permissions
    sudoZstd tmp -c > $INTOVOID
    zstd tmp -f -o tmp.zst
    sudoZstd -d tmp.zst -c > $INTOVOID
    sudoZstd -d tmp.zst -o $INTOVOID
    ls -las $INTOVOID | grep "rw-rw-rw-"
fi


println "\n===>  compress multiple files into an output directory, --output-dir-flat"
println henlo > tmp1
mkdir tmpInputTestDir
mkdir tmpInputTestDir/we
mkdir tmpInputTestDir/we/must
mkdir tmpInputTestDir/we/must/go
mkdir tmpInputTestDir/we/must/go/deeper
println cool > tmpInputTestDir/we/must/go/deeper/tmp2
mkdir tmpOutDir
zstd tmp1 tmpInputTestDir/we/must/go/deeper/tmp2 --output-dir-flat tmpOutDir
test -f tmpOutDir/tmp1.zst
test -f tmpOutDir/tmp2.zst
println "test : decompress multiple files into an output directory, --output-dir-flat"
mkdir tmpOutDirDecomp
zstd tmpOutDir -r -d --output-dir-flat tmpOutDirDecomp
test -f tmpOutDirDecomp/tmp2
test -f tmpOutDirDecomp/tmp1
rm -f tmpOutDirDecomp/*
zstd tmpOutDir -r -d --output-dir-flat=tmpOutDirDecomp
test -f tmpOutDirDecomp/tmp2
test -f tmpOutDirDecomp/tmp1
rm -rf tmp*

if [ "$isWindows" = false ] ; then
    println "\n===>  compress multiple files into an output directory and mirror input folder, --output-dir-mirror"
    println "test --output-dir-mirror" > tmp1
    mkdir -p tmpInputTestDir/we/must/go/deeper
    println cool > tmpInputTestDir/we/must/go/deeper/tmp2
    zstd tmp1 -r tmpInputTestDir --output-dir-mirror tmpOutDir
    test -f tmpOutDir/tmp1.zst
    test -f tmpOutDir/tmpInputTestDir/we/must/go/deeper/tmp2.zst

    println "test: compress input dir will be ignored if it has '..'"
    zstd  -r tmpInputTestDir/we/must/../must --output-dir-mirror non-exist && die "input cannot contain '..'"
    test ! -d non-exist

    println "test : decompress multiple files into an output directory, --output-dir-mirror"
    zstd tmpOutDir -r -d --output-dir-mirror tmpOutDirDecomp
    test -f tmpOutDirDecomp/tmpOutDir/tmp1
    test -f tmpOutDirDecomp/tmpOutDir/tmpInputTestDir/we/must/go/deeper/tmp2

    println "test: decompress input dir will be ignored if it has '..'"
    zstd  -r tmpOutDir/tmpInputTestDir/we/must/../must --output-dir-mirror non-exist && die "input cannot contain '..'"
    test ! -d non-exist

    rm -rf tmp*
fi


println "test : compress multiple files reading them from a file, --filelist=FILE"
println "Hello world!, file1" > tmp1
println "Hello world!, file2" > tmp2
println tmp1 > tmp_fileList
println tmp2 >> tmp_fileList
zstd -f --filelist=tmp_fileList
test -f tmp2.zst
test -f tmp1.zst

println "test : alternate syntax: --filelist FILE"
zstd -f --filelist tmp_fileList
test -f tmp2.zst
test -f tmp1.zst

println "test : reading file list from a symlink, --filelist=FILE"
rm -f *.zst
ln -s tmp_fileList tmp_symLink
zstd -f --filelist=tmp_symLink
test -f tmp2.zst
test -f tmp1.zst

println "test : compress multiple files reading them from multiple files, --filelist=FILE"
rm -f *.zst
println "Hello world!, file3" > tmp3
println "Hello world!, file4" > tmp4
println tmp3 > tmp_fileList2
println tmp4 >> tmp_fileList2
zstd -f --filelist=tmp_fileList --filelist=tmp_fileList2
test -f tmp1.zst
test -f tmp2.zst
test -f tmp3.zst
test -f tmp4.zst

println "test : decompress multiple files reading them from a file, --filelist=FILE"
rm -f tmp1 tmp2
println tmp1.zst > tmpZst
println tmp2.zst >> tmpZst
zstd -d -f --filelist=tmpZst
test -f tmp1
test -f tmp2

println "test : decompress multiple files reading them from multiple files, --filelist=FILE"
rm -f tmp1 tmp2 tmp3 tmp4
println tmp3.zst > tmpZst2
println tmp4.zst >> tmpZst2
zstd -d -f --filelist=tmpZst --filelist=tmpZst2
test -f tmp1
test -f tmp2
test -f tmp3
test -f tmp4

println "test : survive a list of files which is text garbage (--filelist=FILE)"
datagen > tmp_badList
zstd -f --filelist=tmp_badList && die "should have failed : list is text garbage"

println "test : survive a list of files which is binary garbage (--filelist=FILE)"
datagen -P0 -g1M > tmp_badList
zstd -qq -f --filelist=tmp_badList && die "should have failed : list is binary garbage"  # let's avoid printing binary garbage on console

println "test : try to overflow internal list of files (--filelist=FILE)"
touch tmp1 tmp2 tmp3 tmp4 tmp5 tmp6
ls tmp* > tmpList
zstd -f tmp1 --filelist=tmpList --filelist=tmpList tmp2 tmp3  # can trigger an overflow of internal file list
rm -rf tmp*

println "\n===> --[no-]content-size tests"

datagen > tmp_contentsize
zstd -f tmp_contentsize
zstd -lv tmp_contentsize.zst | grep "Decompressed Size:"
zstd -f --no-content-size tmp_contentsize
zstd -lv tmp_contentsize.zst | grep "Decompressed Size:" && die
zstd -f --content-size tmp_contentsize
zstd -lv tmp_contentsize.zst | grep "Decompressed Size:"
zstd -f --content-size --no-content-size tmp_contentsize
zstd -lv tmp_contentsize.zst | grep "Decompressed Size:" && die
rm -rf tmp*

println "test : show-default-cparams regular"
datagen > tmp
zstd --show-default-cparams -f tmp
rm -rf tmp*

println "test : show-default-cparams recursive"
mkdir tmp_files
datagen -g15000 > tmp_files/tmp1
datagen -g129000 > tmp_files/tmp2
datagen -g257000 > tmp_files/tmp3
zstd --show-default-cparams -f -r tmp_files
rm -rf tmp*

println "\n===>  Advanced compression parameters "
println "Hello world!" | zstd --zstd=windowLog=21,      - -o tmp.zst && die "wrong parameters not detected!"
println "Hello world!" | zstd --zstd=windowLo=21        - -o tmp.zst && die "wrong parameters not detected!"
println "Hello world!" | zstd --zstd=windowLog=21,slog  - -o tmp.zst && die "wrong parameters not detected!"
println "Hello world!" | zstd --zstd=strategy=10        - -o tmp.zst && die "parameter out of bound not detected!"  # > btultra2 : does not exist
test ! -f tmp.zst  # tmp.zst should not be created
roundTripTest -g512K
roundTripTest -g512K " --zstd=mml=3,tlen=48,strat=6"
roundTripTest -g512K " --zstd=strat=6,wlog=23,clog=23,hlog=22,slog=6"
roundTripTest -g512K " --zstd=windowLog=23,chainLog=23,hashLog=22,searchLog=6,minMatch=3,targetLength=48,strategy=6"
roundTripTest -g512K " --single-thread --long --zstd=ldmHashLog=20,ldmMinMatch=64,ldmBucketSizeLog=1,ldmHashRateLog=7"
roundTripTest -g512K " --single-thread --long --zstd=lhlog=20,lmml=64,lblog=1,lhrlog=7"
roundTripTest -g64K  "19 --zstd=strat=9"   # btultra2


println "\n===>  Pass-Through mode "
println "Hello world 1!" | zstd -df
println "Hello world 2!" | zstd -dcf
println "Hello world 3!" > tmp1
zstd -dcf tmp1


println "\n===>  frame concatenation "
println "hello " > hello.tmp
println "world!" > world.tmp
cat hello.tmp world.tmp > helloworld.tmp
zstd -c hello.tmp > hello.zst
zstd -c world.tmp > world.zst
cat hello.zst world.zst > helloworld.zst
zstd -dc helloworld.zst > result.tmp
cat result.tmp
$DIFF helloworld.tmp result.tmp
println "frame concatenation without checksum"
zstd -c hello.tmp > hello.zst --no-check
zstd -c world.tmp > world.zst --no-check
cat hello.zst world.zst > helloworld.zstd
zstd -dc helloworld.zst > result.tmp
$DIFF helloworld.tmp result.tmp
println "testing zstdcat symlink"
ln -sf "$ZSTD_BIN" zstdcat
$EXE_PREFIX ./zstdcat helloworld.zst > result.tmp
$DIFF helloworld.tmp result.tmp
ln -s helloworld.zst helloworld.link.zst
$EXE_PREFIX ./zstdcat helloworld.link.zst > result.tmp
$DIFF helloworld.tmp result.tmp
rm zstdcat
rm result.tmp
println "testing zcat symlink"
ln -sf "$ZSTD_BIN" zcat
$EXE_PREFIX ./zcat helloworld.zst > result.tmp
$DIFF helloworld.tmp result.tmp
$EXE_PREFIX ./zcat helloworld.link.zst > result.tmp
$DIFF helloworld.tmp result.tmp
rm zcat
rm ./*.tmp ./*.zstd
println "frame concatenation tests completed"


if [ "$isWindows" = false ] && [ "$UNAME" != 'SunOS' ] && [ "$UNAME" != "OpenBSD" ] ; then
println "\n**** flush write error test **** "

println "println foo | zstd > /dev/full"
println foo | zstd > /dev/full && die "write error not detected!"
println "println foo | zstd | zstd -d > /dev/full"
println foo | zstd | zstd -d > /dev/full && die "write error not detected!"

fi


if [ "$isWindows" = false ] && [ "$UNAME" != 'SunOS' ] ; then

println "\n===>  symbolic link test "

rm -f hello.tmp world.tmp world2.tmp hello.tmp.zst world.tmp.zst
println "hello world" > hello.tmp
ln -s hello.tmp world.tmp
ln -s hello.tmp world2.tmp
zstd world.tmp hello.tmp || true
test -f hello.tmp.zst  # regular file should have been compressed!
test ! -f world.tmp.zst  # symbolic link should not have been compressed!
zstd world.tmp || true
test ! -f world.tmp.zst  # symbolic link should not have been compressed!
zstd world.tmp world2.tmp || true
test ! -f world.tmp.zst  # symbolic link should not have been compressed!
test ! -f world2.tmp.zst  # symbolic link should not have been compressed!
zstd world.tmp hello.tmp -f
test -f world.tmp.zst  # symbolic link should have been compressed with --force
rm -f hello.tmp world.tmp world2.tmp hello.tmp.zst world.tmp.zst

fi


println "\n===>  test sparse file support "

datagen -g5M  -P100 > tmpSparse
zstd tmpSparse -c | zstd -dv -o tmpSparseRegen
$DIFF -s tmpSparse tmpSparseRegen
zstd tmpSparse -c | zstd -dv --sparse -c > tmpOutSparse
$DIFF -s tmpSparse tmpOutSparse
zstd tmpSparse -c | zstd -dv --no-sparse -c > tmpOutNoSparse
$DIFF -s tmpSparse tmpOutNoSparse
ls -ls tmpSparse*  # look at file size and block size on disk
datagen -s1 -g1200007 -P100 | zstd | zstd -dv --sparse -c > tmpSparseOdd   # Odd size file (to not finish on an exact nb of blocks)
datagen -s1 -g1200007 -P100 | $DIFF -s - tmpSparseOdd
ls -ls tmpSparseOdd  # look at file size and block size on disk
println "\n Sparse Compatibility with Console :"
println "Hello World 1 !" | zstd | zstd -d -c
println "Hello World 2 !" | zstd | zstd -d | cat
println "\n Sparse Compatibility with Append :"
datagen -P100 -g1M > tmpSparse1M
cat tmpSparse1M tmpSparse1M > tmpSparse2M
zstd -v -f tmpSparse1M -o tmpSparseCompressed
zstd -d -v -f tmpSparseCompressed -o tmpSparseRegenerated
zstd -d -v -f tmpSparseCompressed -c >> tmpSparseRegenerated
ls -ls tmpSparse*  # look at file size and block size on disk
$DIFF tmpSparse2M tmpSparseRegenerated
rm tmpSparse*


println "\n===>  stream-size mode"

datagen -g11000 > tmp
println "test : basic file compression vs sized streaming compression"
file_size=$(zstd -14 -f tmp -o tmp.zst && wc -c < tmp.zst)
stream_size=$(cat tmp | zstd -14 --stream-size=11000 | wc -c)
if [ "$stream_size" -gt "$file_size" ]; then
  die "hinted compression larger than expected"
fi
println "test : sized streaming compression and decompression"
cat tmp | zstd -14 -f tmp -o tmp.zst --stream-size=11000
zstd -df tmp.zst -o tmp_decompress
cmp tmp tmp_decompress || die "difference between original and decompressed file"
println "test : incorrect stream size"
cat tmp | zstd -14 -f -o tmp.zst --stream-size=11001 && die "should fail with incorrect stream size"

println "\n===>  zstd zero weight dict test "
rm -f tmp*
cp "$TESTDIR/dict-files/zero-weight-dict" tmp_input
zstd -D "$TESTDIR/dict-files/zero-weight-dict" tmp_input
zstd -D "$TESTDIR/dict-files/zero-weight-dict" -d tmp_input.zst -o tmp_decomp
$DIFF tmp_decomp tmp_input
rm -rf tmp*

println "\n===>  zstd (valid) zero weight dict test "
rm -f tmp*
# 0 has a non-zero weight in the dictionary
echo "0000000000000000000000000" > tmp_input
zstd -D "$TESTDIR/dict-files/zero-weight-dict" tmp_input
zstd -D "$TESTDIR/dict-files/zero-weight-dict" -d tmp_input.zst -o tmp_decomp
$DIFF tmp_decomp tmp_input
rm -rf tmp*

println "\n===>  size-hint mode"

datagen -g11000 > tmp
datagen -g11000 > tmp2
datagen > tmpDict
println "test : basic file compression vs hinted streaming compression"
file_size=$(zstd -14 -f tmp -o tmp.zst && wc -c < tmp.zst)
stream_size=$(cat tmp | zstd -14 --size-hint=11000 | wc -c)
if [ "$stream_size" -ge "$file_size" ]; then
  die "hinted compression larger than expected"
fi
println "test : hinted streaming compression and decompression"
cat tmp | zstd -14 -f -o tmp.zst --size-hint=11000
zstd -df tmp.zst -o tmp_decompress
cmp tmp tmp_decompress || die "difference between original and decompressed file"
println "test : hinted streaming compression with dictionary"
cat tmp | zstd -14 -f -D tmpDict --size-hint=11000 | zstd -t -D tmpDict
println "test : multiple file compression with hints and dictionary"
zstd -14 -f -D tmpDict --size-hint=11000 tmp tmp2
zstd -14 -f -o tmp1_.zst -D tmpDict --size-hint=11000 tmp
zstd -14 -f -o tmp2_.zst -D tmpDict --size-hint=11000 tmp2
cmp tmp.zst tmp1_.zst || die "first file's output differs"
cmp tmp2.zst tmp2_.zst || die "second file's output differs"
println "test : incorrect hinted stream sizes"
cat tmp | zstd -14 -f --size-hint=11050 | zstd -t  # slightly too high
cat tmp | zstd -14 -f --size-hint=10950 | zstd -t  # slightly too low
cat tmp | zstd -14 -f --size-hint=22000 | zstd -t  # considerably too high
cat tmp | zstd -14 -f --size-hint=5500  | zstd -t  # considerably too low


println "\n===>  dictionary tests "

println "- test with raw dict (content only) "
datagen > tmpDict
datagen -g1M | $MD5SUM > tmp1
datagen -g1M | zstd -D tmpDict | zstd -D tmpDict -dvq | $MD5SUM > tmp2
$DIFF -q tmp1 tmp2
println "- Create first dictionary "
TESTFILE="$PRGDIR"/zstdcli.c
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict
cp "$TESTFILE" tmp
println "- Test dictionary compression with tmpDict as an input file and dictionary"
zstd -f tmpDict -D tmpDict && die "compression error not detected!"
println "- Dictionary compression roundtrip"
zstd -f tmp -D tmpDict
zstd -d tmp.zst -D tmpDict -fo result
$DIFF "$TESTFILE" result
println "- Dictionary compression with btlazy2 strategy"
zstd -f tmp -D tmpDict --zstd=strategy=6
zstd -d tmp.zst -D tmpDict -fo result
$DIFF "$TESTFILE" result
if [ -n "$hasMT" ]
then
    println "- Test dictionary compression with multithreading "
    datagen -g5M | zstd -T2 -D tmpDict | zstd -t -D tmpDict   # fails with v1.3.2
fi
println "- Create second (different) dictionary "
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c "$PRGDIR"/*.h -o tmpDictC
zstd -d tmp.zst -D tmpDictC -fo result && die "wrong dictionary not detected!"
println "- Create dictionary with short dictID"
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpDict1
cmp tmpDict tmpDict1 && die "dictionaries should have different ID !"
println "- Create dictionary with wrong dictID parameter order (must fail)"
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID -o 1 tmpDict1 && die "wrong order : --dictID must be followed by argument "
println "- Create dictionary with size limit"
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict2 --maxdict=4K -v
println "- Create dictionary with small size limit"
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict3 --maxdict=1K -v
println "- Create dictionary with wrong parameter order (must fail)"
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict3 --maxdict -v 4K && die "wrong order : --maxdict must be followed by argument "
println "- Compress without dictID"
zstd -f tmp -D tmpDict1 --no-dictID
zstd -d tmp.zst -D tmpDict -fo result
$DIFF "$TESTFILE" result
println "- Compress multiple files with dictionary"
rm -rf dirTestDict
mkdir dirTestDict
cp "$TESTDIR"/*.c dirTestDict
cp "$PRGDIR"/*.c dirTestDict
cp "$PRGDIR"/*.h dirTestDict
$MD5SUM dirTestDict/* > tmph1
zstd -f --rm dirTestDict/* -D tmpDictC
zstd -d --rm dirTestDict/*.zst -D tmpDictC  # note : use internal checksum by default
case "$UNAME" in
  Darwin) println "md5sum -c not supported on OS-X : test skipped" ;;  # not compatible with OS-X's md5
  *) $MD5SUM -c tmph1 ;;
esac
rm -rf dirTestDict
println "- dictionary builder on bogus input"
println "Hello World" > tmp
zstd --train-legacy -q tmp && die "Dictionary training should fail : not enough input source"
datagen -P0 -g10M > tmp
zstd --train-legacy -q tmp && die "Dictionary training should fail : source is pure noise"
println "- Test -o before --train"
rm -f tmpDict dictionary
zstd -o tmpDict --train "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f tmpDict
zstd --train "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f dictionary
println "- Test dictionary training fails"
echo "000000000000000000000000000000000" > tmpz
zstd --train tmpz tmpz tmpz tmpz tmpz tmpz tmpz tmpz tmpz && die "Dictionary training should fail : source is all zeros"
if [ -n "$hasMT" ]
then
  zstd --train -T0 tmpz tmpz tmpz tmpz tmpz tmpz tmpz tmpz tmpz && die "Dictionary training should fail : source is all zeros"
  println "- Create dictionary with multithreading enabled"
  zstd --train -T0 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict
fi
rm tmp* dictionary


println "\n===>  fastCover dictionary builder : advanced options "
TESTFILE="$PRGDIR"/zstdcli.c
datagen > tmpDict
println "- Create first dictionary"
zstd --train-fastcover=k=46,d=8,f=15,split=80 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict
cp "$TESTFILE" tmp
zstd -f tmp -D tmpDict
zstd -d tmp.zst -D tmpDict -fo result
$DIFF "$TESTFILE" result
println "- Create second (different) dictionary"
zstd --train-fastcover=k=56,d=8 "$TESTDIR"/*.c "$PRGDIR"/*.c "$PRGDIR"/*.h -o tmpDictC
zstd -d tmp.zst -D tmpDictC -fo result && die "wrong dictionary not detected!"
zstd --train-fastcover=k=56,d=8 && die "Create dictionary without input file"
println "- Create dictionary with short dictID"
zstd --train-fastcover=k=46,d=8,f=15,split=80 "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpDict1
cmp tmpDict tmpDict1 && die "dictionaries should have different ID !"
println "- Create dictionaries with shrink-dict flag enabled"
zstd --train-fastcover=steps=1,shrink "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpShrinkDict
zstd --train-fastcover=steps=1,shrink=1 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpShrinkDict1
zstd --train-fastcover=steps=1,shrink=5 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpShrinkDict2
println "- Create dictionary with size limit"
zstd --train-fastcover=steps=1 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict2 --maxdict=4K
println "- Create dictionary using all samples for both training and testing"
zstd --train-fastcover=k=56,d=8,split=100 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
println "- Create dictionary using f=16"
zstd --train-fastcover=k=56,d=8,f=16 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
zstd --train-fastcover=k=56,d=8,accel=15 -r "$TESTDIR"/*.c "$PRGDIR"/*.c && die "Created dictionary using accel=15"
println "- Create dictionary using accel=2"
zstd --train-fastcover=k=56,d=8,accel=2 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
println "- Create dictionary using accel=10"
zstd --train-fastcover=k=56,d=8,accel=10 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
println "- Create dictionary with multithreading"
zstd --train-fastcover -T4 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
println "- Test -o before --train-fastcover"
rm -f tmpDict dictionary
zstd -o tmpDict --train-fastcover=k=56,d=8 "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f tmpDict
zstd --train-fastcover=k=56,d=8 "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f dictionary
rm tmp* dictionary


println "\n===>  legacy dictionary builder "

TESTFILE="$PRGDIR"/zstdcli.c
datagen > tmpDict
println "- Create first dictionary"
zstd --train-legacy=selectivity=8 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict
cp "$TESTFILE" tmp
zstd -f tmp -D tmpDict
zstd -d tmp.zst -D tmpDict -fo result
$DIFF "$TESTFILE" result
zstd --train-legacy=s=8 && die "Create dictionary without input files (should error)"
println "- Create second (different) dictionary"
zstd --train-legacy=s=5 "$TESTDIR"/*.c "$PRGDIR"/*.c "$PRGDIR"/*.h -o tmpDictC
zstd -d tmp.zst -D tmpDictC -fo result && die "wrong dictionary not detected!"
println "- Create dictionary with short dictID"
zstd --train-legacy -s5 "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpDict1
cmp tmpDict tmpDict1 && die "dictionaries should have different ID !"
println "- Create dictionary with size limit"
zstd --train-legacy -s9 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict2 --maxdict=4K
println "- Test -o before --train-legacy"
rm -f tmpDict dictionary
zstd -o tmpDict --train-legacy "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f tmpDict
zstd --train-legacy "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f dictionary
rm tmp* dictionary


println "\n===>  integrity tests "

println "test one file (tmp1.zst) "
datagen > tmp1
zstd tmp1
zstd -t tmp1.zst
zstd --test tmp1.zst
println "test multiple files (*.zst) "
zstd -t ./*.zst
println "test bad files (*) "
zstd -t ./* && die "bad files not detected !"
zstd -t tmp1 && die "bad file not detected !"
cp tmp1 tmp2.zst
zstd -t tmp2.zst && die "bad file not detected !"
datagen -g0 > tmp3
zstd -t tmp3 && die "bad file not detected !"   # detects 0-sized files as bad
println "test --rm and --test combined "
zstd -t --rm tmp1.zst
test -f tmp1.zst   # check file is still present
split -b16384 tmp1.zst tmpSplit.
zstd -t tmpSplit.* && die "bad file not detected !"
datagen | zstd -c | zstd -t


println "\n===>  golden files tests "

zstd -t -r "$TESTDIR/golden-decompression"
zstd -c -r "$TESTDIR/golden-compression" | zstd -t
zstd -D "$TESTDIR/golden-dictionaries/http-dict-missing-symbols" "$TESTDIR/golden-compression/http" -c | zstd -D "$TESTDIR/golden-dictionaries/http-dict-missing-symbols" -t


println "\n===>  benchmark mode tests "

println "bench one file"
datagen > tmp1
zstd -bi0 tmp1
println "bench multiple levels"
zstd -i0b0e3 tmp1
println "bench negative level"
zstd -bi0 --fast tmp1
println "with recursive and quiet modes"
zstd -rqi0b1e2 tmp1
println "benchmark decompression only"
zstd -f tmp1
zstd -b -d -i0 tmp1.zst


println "\n===>  zstd compatibility tests "

datagen > tmp
rm -f tmp.zst
zstd --format=zstd -f tmp
test -f tmp.zst


println "\n===>  gzip compatibility tests "

GZIPMODE=1
zstd --format=gzip -V || GZIPMODE=0
if [ $GZIPMODE -eq 1 ]; then
    println "gzip support detected"
    GZIPEXE=1
    gzip -V || GZIPEXE=0
    if [ $GZIPEXE -eq 1 ]; then
        datagen > tmp
        zstd --format=gzip -f tmp
        gzip -t -v tmp.gz
        gzip -f tmp
        zstd -d -f -v tmp.gz
        rm tmp*
    else
        println "gzip binary not detected"
    fi
else
    println "gzip mode not supported"
fi


println "\n===>  gzip frame tests "

if [ $GZIPMODE -eq 1 ]; then
    datagen > tmp
    zstd -f --format=gzip tmp
    zstd -f tmp
    cat tmp.gz tmp.zst tmp.gz tmp.zst | zstd -d -f -o tmp
    truncateLastByte tmp.gz | zstd -t > $INTOVOID && die "incomplete frame not detected !"
    rm tmp*
else
    println "gzip mode not supported"
fi

if [ $GZIPMODE -eq 1 ]; then
    datagen > tmp
    rm -f tmp.zst
    zstd --format=gzip --format=zstd -f tmp
    test -f tmp.zst
fi

println "\n===>  xz compatibility tests "

LZMAMODE=1
zstd --format=xz -V || LZMAMODE=0
if [ $LZMAMODE -eq 1 ]; then
    println "xz support detected"
    XZEXE=1
    xz -Q -V && lzma -Q -V || XZEXE=0
    if [ $XZEXE -eq 1 ]; then
        println "Testing zstd xz and lzma support"
        datagen > tmp
        zstd --format=lzma -f tmp
        zstd --format=xz -f tmp
        xz -Q -t -v tmp.xz
        xz -Q -t -v tmp.lzma
        xz -Q -f -k tmp
        lzma -Q -f -k --lzma1 tmp
        zstd -d -f -v tmp.xz
        zstd -d -f -v tmp.lzma
        rm tmp*
        println "Creating symlinks"
        ln -s "$ZSTD_BIN" ./xz
        ln -s "$ZSTD_BIN" ./unxz
        ln -s "$ZSTD_BIN" ./lzma
        ln -s "$ZSTD_BIN" ./unlzma
        println "Testing xz and lzma symlinks"
        datagen > tmp
        ./xz tmp
        xz -Q -d tmp.xz
        ./lzma tmp
        lzma -Q -d tmp.lzma
        println "Testing unxz and unlzma symlinks"
        xz -Q tmp
        ./xz -d tmp.xz
        lzma -Q tmp
        ./lzma -d tmp.lzma
        rm xz unxz lzma unlzma
        rm tmp*
    else
        println "xz binary not detected"
    fi
else
    println "xz mode not supported"
fi


println "\n===>  xz frame tests "

if [ $LZMAMODE -eq 1 ]; then
    datagen > tmp
    zstd -f --format=xz tmp
    zstd -f --format=lzma tmp
    zstd -f tmp
    cat tmp.xz tmp.lzma tmp.zst tmp.lzma tmp.xz tmp.zst | zstd -d -f -o tmp
    truncateLastByte tmp.xz | zstd -t > $INTOVOID && die "incomplete frame not detected !"
    truncateLastByte tmp.lzma | zstd -t > $INTOVOID && die "incomplete frame not detected !"
    rm tmp*
else
    println "xz mode not supported"
fi

println "\n===>  lz4 compatibility tests "

LZ4MODE=1
zstd --format=lz4 -V || LZ4MODE=0
if [ $LZ4MODE -eq 1 ]; then
    println "lz4 support detected"
    LZ4EXE=1
    lz4 -V || LZ4EXE=0
    if [ $LZ4EXE -eq 1 ]; then
        datagen > tmp
        zstd --format=lz4 -f tmp
        lz4 -t -v tmp.lz4
        lz4 -f tmp
        zstd -d -f -v tmp.lz4
        rm tmp*
    else
        println "lz4 binary not detected"
    fi
else
    println "lz4 mode not supported"
fi


if [ $LZ4MODE -eq 1 ]; then
    println "\n===>  lz4 frame tests "
    datagen > tmp
    zstd -f --format=lz4 tmp
    zstd -f tmp
    cat tmp.lz4 tmp.zst tmp.lz4 tmp.zst | zstd -d -f -o tmp
    truncateLastByte tmp.lz4 | zstd -t > $INTOVOID && die "incomplete frame not detected !"
    rm tmp*
else
    println "\nlz4 mode not supported"
fi


println "\n===> suffix list test"

! zstd -d tmp.abc 2> tmplg

if [ $GZIPMODE -ne 1 ]; then
    grep ".gz" tmplg > $INTOVOID && die "Unsupported suffix listed"
fi

if [ $LZMAMODE -ne 1 ]; then
    grep ".lzma" tmplg > $INTOVOID && die "Unsupported suffix listed"
    grep ".xz" tmplg > $INTOVOID && die "Unsupported suffix listed"
fi

if [ $LZ4MODE -ne 1 ]; then
    grep ".lz4" tmplg > $INTOVOID && die "Unsupported suffix listed"
fi


println "\n===>  tar extension tests "

rm -f tmp tmp.tar tmp.tzst tmp.tgz tmp.txz tmp.tlz4

datagen > tmp
tar cf tmp.tar tmp
zstd tmp.tar -o tmp.tzst
rm tmp.tar
zstd -d tmp.tzst
[ -e tmp.tar ] || die ".tzst failed to decompress to .tar!"
rm -f tmp.tar tmp.tzst

if [ $GZIPMODE -eq 1 ]; then
    tar czf tmp.tgz tmp
    zstd -d tmp.tgz
    [ -e tmp.tar ] || die ".tgz failed to decompress to .tar!"
    rm -f tmp.tar tmp.tgz
fi

if [ $LZMAMODE -eq 1 ]; then
    tar c tmp | zstd --format=xz > tmp.txz
    zstd -d tmp.txz
    [ -e tmp.tar ] || die ".txz failed to decompress to .tar!"
    rm -f tmp.tar tmp.txz
fi

if [ $LZ4MODE -eq 1 ]; then
    tar c tmp | zstd --format=lz4 > tmp.tlz4
    zstd -d tmp.tlz4
    [ -e tmp.tar ] || die ".tlz4 failed to decompress to .tar!"
    rm -f tmp.tar tmp.tlz4
fi

touch tmp.t tmp.tz tmp.tzs
! zstd -d tmp.t
! zstd -d tmp.tz
! zstd -d tmp.tzs


println "\n===>  zstd round-trip tests "

roundTripTest
roundTripTest -g15K       # TableID==3
roundTripTest -g127K      # TableID==2
roundTripTest -g255K      # TableID==1
roundTripTest -g522K      # TableID==0
roundTripTest -g519K 6    # greedy, hash chain
roundTripTest -g517K 16   # btlazy2
roundTripTest -g516K 19   # btopt

fileRoundTripTest -g500K

println "\n===>  zstd long distance matching round-trip tests "
roundTripTest -g0 "2 --single-thread --long"
roundTripTest -g1000K "1 --single-thread --long"
roundTripTest -g517K "6 --single-thread --long"
roundTripTest -g516K "16 --single-thread --long"
roundTripTest -g518K "19 --single-thread --long"
fileRoundTripTest -g5M "3 --single-thread --long"


roundTripTest -g96K "5 --single-thread"
if [ -n "$hasMT" ]
then
    println "\n===>  zstdmt round-trip tests "
    roundTripTest -g4M "1 -T0"
    roundTripTest -g8M "3 -T2"
    roundTripTest -g8000K "2 --threads=2"
    fileRoundTripTest -g4M "19 -T2 -B1M"

    println "\n===>  zstdmt long distance matching round-trip tests "
    roundTripTest -g8M "3 --long=24 -T2"

    println "\n===>  ovLog tests "
    datagen -g2MB > tmp
    refSize=$(zstd tmp -6 -c --zstd=wlog=18         | wc -c)
    ov9Size=$(zstd tmp -6 -c --zstd=wlog=18,ovlog=9 | wc -c)
    ov1Size=$(zstd tmp -6 -c --zstd=wlog=18,ovlog=1 | wc -c)
    if [ "$refSize" -eq "$ov9Size" ]; then
        echo ov9Size should be different from refSize
        exit 1
    fi
    if [ "$refSize" -eq "$ov1Size" ]; then
        echo ov1Size should be different from refSize
        exit 1
    fi
    if [ "$ov9Size" -ge "$ov1Size" ]; then
        echo ov9Size="$ov9Size" should be smaller than ov1Size="$ov1Size"
        exit 1
    fi

else
    println "\n===>  no multithreading, skipping zstdmt tests "
fi

rm tmp*

println "\n===>  zstd --list/-l single frame tests "
datagen > tmp1
datagen > tmp2
datagen > tmp3
zstd tmp*
zstd -l ./*.zst
zstd -lv ./*.zst | grep "Decompressed Size:"  # check that decompressed size is present in header
zstd --list ./*.zst
zstd --list -v ./*.zst

println "\n===>  zstd --list/-l multiple frame tests "
cat tmp1.zst tmp2.zst > tmp12.zst
cat tmp12.zst tmp3.zst > tmp123.zst
zstd -l ./*.zst
zstd -lv ./*.zst

println "\n===>  zstd --list/-l error detection tests "
zstd -l tmp1 tmp1.zst && die "-l must fail on non-zstd file"
zstd --list tmp* && die "-l must fail on non-zstd file"
zstd -lv tmp1* && die "-l must fail on non-zstd file"
zstd --list -v tmp2 tmp12.zst && die "-l must fail on non-zstd file"

println "test : detect truncated compressed file "
TEST_DATA_FILE=truncatable-input.txt
FULL_COMPRESSED_FILE=${TEST_DATA_FILE}.zst
TRUNCATED_COMPRESSED_FILE=truncated-input.txt.zst
datagen -g50000 > $TEST_DATA_FILE
zstd -f $TEST_DATA_FILE -o $FULL_COMPRESSED_FILE
dd bs=1 count=100 if=$FULL_COMPRESSED_FILE of=$TRUNCATED_COMPRESSED_FILE
zstd --list $TRUNCATED_COMPRESSED_FILE && die "-l must fail on truncated file"

rm $TEST_DATA_FILE
rm $FULL_COMPRESSED_FILE
rm $TRUNCATED_COMPRESSED_FILE

println "\n===>  zstd --list/-l errors when presented with stdin / no files"
zstd -l && die "-l must fail on empty list of files"
zstd -l - && die "-l does not work on stdin"
zstd -l < tmp1.zst && die "-l does not work on stdin"
zstd -l - < tmp1.zst && die "-l does not work on stdin"
zstd -l - tmp1.zst && die "-l does not work on stdin"
zstd -l - tmp1.zst < tmp1.zst && die "-l does not work on stdin"
zstd -l tmp1.zst < tmp2.zst # this will check tmp1.zst, but not tmp2.zst, which is not an error : zstd simply doesn't read stdin in this case. It must not error just because stdin is not a tty

println "\n===>  zstd --list/-l test with null files "
datagen -g0 > tmp5
zstd tmp5
zstd -l tmp5.zst
zstd -l tmp5* && die "-l must fail on non-zstd file"
zstd -lv tmp5.zst | grep "Decompressed Size: 0.00 KB (0 B)"  # check that 0 size is present in header
zstd -lv tmp5* && die "-l must fail on non-zstd file"

println "\n===>  zstd --list/-l test with no content size field "
datagen -g513K | zstd > tmp6.zst
zstd -l tmp6.zst
zstd -lv tmp6.zst | grep "Decompressed Size:"  && die "Field :Decompressed Size: should not be available in this compressed file"

println "\n===>   zstd --list/-l test with no checksum "
zstd -f --no-check tmp1
zstd -l tmp1.zst
zstd -lv tmp1.zst

rm tmp*


println "\n===>   zstd long distance matching tests "
roundTripTest -g0 " --single-thread --long"
roundTripTest -g9M "2 --single-thread --long"
# Test parameter parsing
roundTripTest -g1M -P50 "1 --single-thread --long=29" " --memory=512MB"
roundTripTest -g1M -P50 "1 --single-thread --long=29 --zstd=wlog=28" " --memory=256MB"
roundTripTest -g1M -P50 "1 --single-thread --long=29" " --long=28 --memory=512MB"
roundTripTest -g1M -P50 "1 --single-thread --long=29" " --zstd=wlog=28 --memory=512MB"




if [ "$1" != "--test-large-data" ]; then
    println "Skipping large data tests"
    exit 0
fi


#############################################################################


if [ -n "$hasMT" ]
then
    println "\n===>   adaptive mode "
    roundTripTest -g270000000 " --adapt"
    roundTripTest -g27000000 " --adapt=min=1,max=4"
    println "===>   test: --adapt must fail on incoherent bounds "
    datagen > tmp
    zstd -f -vv --adapt=min=10,max=9 tmp && die "--adapt must fail on incoherent bounds"

    println "\n===>   rsyncable mode "
    roundTripTest -g10M " --rsyncable"
    roundTripTest -g10M " --rsyncable -B100K"
    println "===>   test: --rsyncable must fail with --single-thread"
    zstd -f -vv --rsyncable --single-thread tmp && die "--rsyncable must fail with --single-thread"
fi

println "\n===> patch-from=origin tests"
datagen -g1000 -P50 > tmp_dict
datagen -g1000 -P10 > tmp_patch
zstd --patch-from=tmp_dict tmp_patch -o tmp_patch_diff
zstd -d --patch-from=tmp_dict tmp_patch_diff -o tmp_patch_recon
$DIFF -s tmp_patch_recon tmp_patch

println "\n===> alternate syntax: patch-from origin"
zstd -f --patch-from tmp_dict tmp_patch -o tmp_patch_diff
zstd -df --patch-from tmp_dict tmp_patch_diff -o tmp_patch_recon
$DIFF -s tmp_patch_recon tmp_patch
rm -rf tmp_*

println "\n===> patch-from recursive tests"
mkdir tmp_dir
datagen > tmp_dir/tmp1
datagen > tmp_dir/tmp2
datagen > tmp_dict
zstd --patch-from=tmp_dict -r tmp_dir && die
rm -rf tmp*

println "\n===> patch-from long mode trigger larger file test"
datagen -g5000000 > tmp_dict
datagen -g5000000 > tmp_patch
zstd -15 --patch-from=tmp_dict tmp_patch 2>&1 | grep "long mode automatically triggered"
rm -rf tmp*

println "\n===> patch-from --stream-size test"
datagen -g1000 -P50 > tmp_dict
datagen -g1000 -P10 > tmp_patch
cat tmp_patch | zstd -f --patch-from=tmp_dict -c -o tmp_patch_diff && die
cat tmp_patch | zstd -f --patch-from=tmp_dict --stream-size=1000 -c -o tmp_patch_diff
rm -rf tmp*

println "\n===>   large files tests "

roundTripTest -g270000000 1
roundTripTest -g250000000 2
roundTripTest -g230000000 3

roundTripTest -g140000000 -P60 4
roundTripTest -g130000000 -P62 5
roundTripTest -g120000000 -P65 6

roundTripTest -g70000000 -P70 7
roundTripTest -g60000000 -P71 8
roundTripTest -g50000000 -P73 9

roundTripTest -g35000000 -P75 10
roundTripTest -g30000000 -P76 11
roundTripTest -g25000000 -P78 12

roundTripTest -g18000013 -P80 13
roundTripTest -g18000014 -P80 14
roundTripTest -g18000015 -P81 15
roundTripTest -g18000016 -P84 16
roundTripTest -g18000017 -P88 17
roundTripTest -g18000018 -P94 18
roundTripTest -g18000019 -P96 19

roundTripTest -g5000000000 -P99 "1 --zstd=wlog=25"
roundTripTest -g3700000000 -P0 "1 --zstd=strategy=6,wlog=25"   # ensure btlazy2 can survive an overflow rescale

fileRoundTripTest -g4193M -P99 1


println "\n===>   zstd long, long distance matching round-trip tests "
roundTripTest -g270000000 "1 --single-thread --long"
roundTripTest -g130000000 -P60 "5 --single-thread --long"
roundTripTest -g35000000 -P70 "8 --single-thread --long"
roundTripTest -g18000001 -P80  "18 --single-thread --long"
# Test large window logs
roundTripTest -g700M -P50 "1 --single-thread --long=29"
roundTripTest -g600M -P50 "1 --single-thread --long --zstd=wlog=29,clog=28"


if [ -n "$hasMT" ]
then
    println "\n===>   zstdmt long round-trip tests "
    roundTripTest -g80000000 -P99 "19 -T2" " "
    roundTripTest -g5000000000 -P99 "1 -T2" " "
    roundTripTest -g500000000 -P97 "1 -T999" " "
    fileRoundTripTest -g4103M -P98 " -T0" " "
    roundTripTest -g400000000 -P97 "1 --long=24 -T2" " "
    # Exposes the bug in https://github.com/facebook/zstd/pull/1678
    # This test fails on 4 different travis builds at the time of writing
    # because it needs to allocate 8 GB of memory.
    # roundTripTest -g10G -P99 "1 -T1 --long=31 --zstd=clog=27 --fast=1000"
else
    println "\n**** no multithreading, skipping zstdmt tests **** "
fi


println "\n===>  cover dictionary builder : advanced options "

TESTFILE="$PRGDIR"/zstdcli.c
datagen > tmpDict
println "- Create first dictionary"
zstd --train-cover=k=46,d=8,split=80 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict
cp "$TESTFILE" tmp
zstd -f tmp -D tmpDict
zstd -d tmp.zst -D tmpDict -fo result
$DIFF "$TESTFILE" result
zstd --train-cover=k=56,d=8 && die "Create dictionary without input file (should error)"
println "- Create second (different) dictionary"
zstd --train-cover=k=56,d=8 "$TESTDIR"/*.c "$PRGDIR"/*.c "$PRGDIR"/*.h -o tmpDictC
zstd -d tmp.zst -D tmpDictC -fo result && die "wrong dictionary not detected!"
println "- Create dictionary using shrink-dict flag"
zstd --train-cover=steps=256,shrink "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpShrinkDict
zstd --train-cover=steps=256,shrink=1 "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpShrinkDict1
zstd --train-cover=steps=256,shrink=5 "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpShrinkDict2
println "- Create dictionary with short dictID"
zstd --train-cover=k=46,d=8,split=80 "$TESTDIR"/*.c "$PRGDIR"/*.c --dictID=1 -o tmpDict1
cmp tmpDict tmpDict1 && die "dictionaries should have different ID !"
println "- Create dictionary with size limit"
zstd --train-cover=steps=8 "$TESTDIR"/*.c "$PRGDIR"/*.c -o tmpDict2 --maxdict=4K
println "- Compare size of dictionary from 90% training samples with 80% training samples"
zstd --train-cover=split=90 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
zstd --train-cover=split=80 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
println "- Create dictionary using all samples for both training and testing"
zstd --train-cover=split=100 -r "$TESTDIR"/*.c "$PRGDIR"/*.c
println "- Test -o before --train-cover"
rm -f tmpDict dictionary
zstd -o tmpDict --train-cover "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f tmpDict
zstd --train-cover "$TESTDIR"/*.c "$PRGDIR"/*.c
test -f dictionary
rm -f tmp* dictionary

rm -f tmp*
