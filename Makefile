as=nasm
asflags=-fbin -O0

target=bin/Nyanix
entry=src/boot_early/boot.s

.PHONY: all clean debug qemu install

all: check clean install

check:
	@command -v nasm >/dev/null 2>&1 || { \
		echo "nasm assembler not found"; \
		echo "Abort"; \
		exit 1; \
	}

clean:
	rm -rf bin/*

debug:
	$(as) $(asflags) -g -o $(target) $(entry)

qemu:
	qemu-system-x86_64 -d in_asm $(target)

install:
	mkdir -p bin
	$(as) $(asflags) -o $(target) $(entry)

