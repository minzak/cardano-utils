#COLD VOLUME

PRFX=node2
CRVLM='/mnt/crypt/crypt_cold_'$PRFX'.img'
CRVLM_NAME='crypt_cold_'$PRFX
CRVLM_PATH=/opt/cardano/cold-keys

cryptsetup -q luksOpen $CRVLM $CRVLM_NAME
mount /dev/mapper/$CRVLM_NAME $CRVLM_PATH
ls -latrh $CRVLM_PATH
