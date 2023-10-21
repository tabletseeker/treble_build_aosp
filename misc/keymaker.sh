#!/bin/bash

KEYS="$PWD/build/make/target/product/security"

echo -e "\n Creating new signing keys and deleting old..."

	for x in ls "$KEYS"/*

	do
		if echo "$x" | grep -Eq "releasekey|testkey|platform|shared|media|networkstack";then 
		
			rm -f "$x"
			
		fi
		
	done

subject='/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'

for x in releasekey testkey platform shared media networkstack; do \

    ./development/tools/make_key "$KEYS"/$x "$subject"; \

done

