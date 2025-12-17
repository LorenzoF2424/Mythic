set -e

#variables
SOURCE="./SystemSource"
DEST="./System"
TEMP="./tempfiles"
export PATH="/home/lorenzo/OSDev/cross-compiler/cross-gcc/bin:$PATH"
OSFILENAME="MythicOS"


echo "==================================================================="
echo "Converting OS Source Files to bootable Hard Disk....."
echo "==================================================================="
echo ""

echo "1) Assembling Bootloader....."
nasm -f bin $SOURCE/sysboot/bootloader.asm -o $TEMP/bootloader.img || {
    echo ""
    echo "NASM bootloader compile ERROR!!!"
    exit 1
}

echo "Bootloader Assembly Successfull!!!"
echo "-------------------------------------------------------------------"

echo "2) Assembling Kernel Entry File....."
nasm -f elf32 $SOURCE/sysboot/kernel_entry.asm -o $TEMP/kernel_entry.o || {
    echo ""
    echo "NASM kernel_entry compile ERROR!"
    exit 1
}

echo "Kernel Entry Assembly Successfull!!!"
echo "-------------------------------------------------------------------"


echo "2.5) Assembling padding file full of zeroes........"
nasm -f bin $SOURCE/sysboot/zeroes.asm -o $TEMP/zeroes.bin
echo "-------------------------------------------------------------------"

echo "3) Compiling and Linking C++ kernel to boot loader......"
x86_64-elf-g++ -ffreestanding -m32 -g -c "$SOURCE/syskernel/kernel32VGA.cpp" -o "$TEMP/kernel32VGA.o" \
   -O2 -Wall -Wextra -fno-exceptions -fno-rtti
x86_64-elf-ld -m elf_i386 -T linker.ld --oformat binary -o "$TEMP/kernel32VGA_with_entry.bin" \
                    "$TEMP/kernel_entry.o" "$TEMP/kernel32VGA.o"
echo "-------------------------------------------------------------------"

echo "4) Uniting the bootloader and the kernel"
echo "   then the padding zeroes at the end......"
cat $TEMP/bootloader.img $TEMP/kernel32VGA_with_entry.bin > $TEMP/$OSFILENAME_no_zeroes.bin
cat $TEMP/$OSFILENAME_no_zeroes.bin $TEMP/zeroes.bin > $TEMP/$OSFILENAME.bin
echo "-------------------------------------------------------------------"

echo "4.5)Bootloader + kernel_entry + kernel C++ file INFO:"
ls -l "$TEMP/$OSFILENAME.bin"
echo "-------------------------------------------------------------------"

echo "5) Creating IMG File....."
dd if=/dev/zero of=empty_hard_disk.img bs=1M count=10
dd if=$TEMP/$OSFILENAME.bin of=$OSFILENAME.img conv=notrunc

#qemu-img convert -f raw -O vdi $OSFILENAME.img $OSFILENAME.vdi
echo "CREATION OF HARD DISK IMAGE \"$OSFILENAME.img\" SUCCESSFULL!!!!"
echo "==================================================================="


echo "Starting $OSFILENAME.img on QEMU....."
echo "==================================================================="

qemu-system-x86_64 -drive format=raw,file=$OSFILENAME.img