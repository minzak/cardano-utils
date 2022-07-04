#COLD VOLUME

PRFX=node2
CRVLM='/mnt/crypt/crypt_cold_'$PRFX'.img'
CRVLM_NAME='crypt_cold_'$PRFX
CRVLM_PATH=/opt/cardano/cold-keys

ls -latrh $CRVLM_PATH
cd ~
umount $CRVLM_PATH
cryptsetup close $CRVLM_NAME
