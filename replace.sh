sed -i "s/^\t\[MBC1SRamEnable\],/\tld/g" $(git ls-files | grep "\.asm")
# $1: phrase to find
# $2: phrase to replace $1