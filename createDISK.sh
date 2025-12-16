
set -e
echo "Converting Folder to ISO File....."
echo "Assembling Bootloader....."


SOURCE="./SystemSource"
DEST="./System"
TEMP="./tempfiles"
export PATH="/home/lorenzo/OSDev/cross-compiler/cross-gcc/bin:$PATH"


nasm -f bin $SOURCE/sysboot/bootloader.asm -o $DEST/sysboot/bootloader.img || {
    echo ""
    echo "NASM bootloader compile error!"
    
    exit 1
}

echo "Bootloader Assembly Successfull!!!"

nasm -f elf32 $SOURCE/sysboot/kernel_entry.asm -o $DEST/sysboot/kernel_entry.img || {
    echo ""
    echo "NASM kernel_entry compile error!"
    
    exit 1
}

echo "Kernel Entry Assembly Successfull!!!"



#truncate -s 2048 bootloader.img
echo "Creating IMG File....."


# 1. Crea un file vuoto da 10MB
dd if=/dev/zero of=hard_disk.img bs=1M count=10

# 2. Unisci il tuo codice (Boot + Extended + Kernel)
#cat $DEST/sysboot/bootloader.img $DEST/sysboot/test_kernel.img > $TEMP/os-image.bin
#cat $DEST/sysboot/bootloader.img $DEST/sysboot/test_kernel.img > $TEMP/os-image.bin

echo "Compiling and Linking C++ kernel to boot loader......"

nasm "$SOURCE/sysboot/kernel_entry.asm" -f elf -o "$TEMP/kernel_entry.o"
nasm "$SOURCE/sysboot/test_kernel.asm" -f bin -o "$TEMP/test_kernel.bin"
x86_64-elf-g++ -ffreestanding -m32 -g -c "$SOURCE/syskernel/kernel.cpp" -o "$TEMP/kernel.o" -O2 -Wall -Wextra -fno-exceptions -fno-rtti
x86_64-elf-ld -m elf_i386 -T linker.ld --oformat binary -o "$TEMP/kernel32.bin" "$TEMP/kernel_entry.o" "$TEMP/kernel.o"
cat $DEST/sysboot/bootloader.img $TEMP/kernel32.bin > $TEMP/os-image.bin
echo ""

echo Bootloader + kernel_entry + kernel C++ file SIZE:
ls -l "$TEMP/os-image.bin"
echo ""
# 3. Scrivi il sistema operativo all'inizio del disco rigido
dd if=$TEMP/os-image.bin of=MythicOS.img conv=notrunc
# Avvia

qemu-img convert -f raw -O vdi MythicOS.img MythicOS.vdi

echo "Starting QEMU....."
qemu-system-x86_64 -drive format=raw,file=MythicOS.img