
#set -e
echo "Converting Folder to ISO File....."
echo "Assembling Bootloader....."

SOURCE="./SystemSource"
DEST="./System"
TEMP="./tempfiles"
export PATH="/home/lorenzo/OSDev/cross-compiler/cross-gcc/bin:$PATH"


nasm -f bin $SOURCE/sysboot/bootloader.asm -o $DEST/sysboot/bootloader.img || {
    echo ""
    echo "NASM compile error!"
    
    exit 1
}

echo "Bootloader Assembly Successfull!!!"

#nasm "$SOURCE/sysboot/kernel_entry.asm" -f elf -o "$TEMP/kernel_entry.o"
#nasm "$SOURCE/sysboot/test_kernel.asm" -f bin -o "$TEMP/test_kernel.bin"
#x86_64-elf-g++ -ffreestanding -m32 -g -c "$SOURCE/syskernel/kernel.cpp" -o "$TEMP/kernel.o"
#x86_64-elf-ld -m elf_i386 -T linker.ld -o "$TEMP/kernel.bin" "$TEMP/kernel_entry.o" "$TEMP/kernel.o"
cat "$DEST/sysboot/bootloader.img" "$TEMP/test_kernel.bin" > "$DEST/syskernel/kernel32.img"

#truncate -s 2048 bootloader.img
echo "Creating ISO File....."
genisoimage -R -J \
  -o ./MythicOS.iso \
  -b syskernel/kernel32.img \
  -c boot.cat \
  -iso-level 2 \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  $DEST



echo "Starting QEMU....."
qemu-system-x86_64 -cdrom ./MythicOS.iso