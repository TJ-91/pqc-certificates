#!/bin/bash

# expects $1 = filename without .pem ending
pem_to_der() {
   awk '/-----BEGIN/,/-----END/ {if (!/-----/) printf "%s", $0}' $1.pem | base64 -d > $1.der
}

gen() {
   if [ "$1" = "MLDSA44" ]
   then
   	ALGO="ML-DSA"
   	PARAMS="ML-DSA-4x4"
   elif [ "$1" = "MLDSA65" ]
   then
   	ALGO="ML-DSA"
   	PARAMS="ML-DSA-6x5"
   elif [ "$1" = "MLDSA87" ]
   then
   	ALGO="ML-DSA"
   	PARAMS="ML-DSA-8x7"
   fi

   
   botan keygen --algo=${ALGO} --params=${PARAMS} > "${ALGO}-${2}_ta_priv.pem"
   botan keygen --algo=${ALGO} --params=${PARAMS} > "${ALGO}-${2}_ca_priv.pem"
   # botan keygen --algo=${ALGO} --params=${PARAMS} > "${ALGO}-${2}_ee_priv.pem"
   
   botan gen_self_signed "${ALGO}-${2}_ta_priv.pem" "Trust Root CA ${PARAMS}" --ca > "${ALGO}-${2}_ta.pem"
   
   botan gen_pkcs10 "${ALGO}-${2}_ca_priv.pem" "CA ${PARAMS}" --ca > "${ALGO}-${2}_ca.csr.pem"
   botan sign_cert "${ALGO}-${2}_ta.pem" "${ALGO}-${2}_ta_priv.pem" "${ALGO}-${2}_ca.csr.pem" > "${ALGO}-${2}_ca.pem"

   # Do not create the ee cert for signature algorithms since ee is interpreted as KEM   
   # botan gen_pkcs10 "${ALGO}-${2}_ee_priv.pem" "End Entity ${PARAMS}" > "${ALGO}-${2}_ee.csr.pem"
   # botan sign_cert "${ALGO}-${2}_ca.pem" "${ALGO}-${2}_ca_priv.pem" "${ALGO}-${2}_ee.csr.pem" > "${ALGO}-${2}_ee.pem"

   # convert to .der
   pem_to_der ${ALGO}-${2}_ta
   pem_to_der ${ALGO}-${2}_ca
   # pem_to_der ${ALGO}-${2}_ee

   # TODO: priv only for 
   # pem_to_der ${ALGO}-${2}_ta_priv
   # pem_to_der ${ALGO}-${2}_ca_priv
   # pem_to_der ${ALGO}-${2}_ee_priv
}

# Sub folders for the provider
ARTIFACTDIRS=default

for dir in ${ARTIFACTDIRS} ; do 

   # Generates the product's directory (if missing)
   [ -d "${dir}" ] || mkdir -p "${dir}"
   [ -d "${dir}i/artifacts" ] || mkdir -p "${dir}/artifacts"

   # PQC Implementation
   $(cd ${dir}/artifacts && gen MLDSA44 2.16.840.1.101.3.4.3.17)
   $(cd ${dir}/artifacts && gen MLDSA65 2.16.840.1.101.3.4.3.18)
   $(cd ${dir}/artifacts && gen MLDSA87 2.16.840.1.101.3.4.3.19)

   # cleanup .pem
   $(cd ${dir}/artifacts && rm *.pem)

done

exit 0;