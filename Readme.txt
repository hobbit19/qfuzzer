
A tiny fuzzer trying to break Qemu-emulator, non KVM mode.
Using Nyanix-bootloader (http://nyan.us) as skeleton-bootloader.

Steps after running ./fuzzer.py:

	Build Nyanix bootloader (old buggy version)
	Generate random binary & append it to Nyanix-skeleton
	Run qemu with generated bootloader, and monitor results.

Not too fancy, but works, kinda. :)




