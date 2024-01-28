{ pkgs, stdenv }:
metadata:

let
  domain = metadata.domain;
  certFile = "${domain}.crt";
  keyFile = "${domain}.key";
  trustedCertFile = "${domain}.pem";
in stdenv.mkDerivation rec {
  name = "generate-ssc";
  version = "0.1.0";
  src = ./.;

  # buildPhase = ''
  #   # Generate a private key
  #   openssl genpkey -algorithm RSA -out "${keyFile}"
  #
  #   # Generate a certificate signing request (CSR)
  #   openssl req -new -key "${keyFile}" -out "${domain}.csr" -subj "/CN=${domain}"
  #
  #   # Generate a self-signed certificate valid for 365 days
  #   openssl x509 -req -in "${domain}.csr" -signkey "${keyFile}" -out "${certFile}" -days 365
  #
  #   # Concatenate the certificate and private key for trusted certificate
  #   cat "${certFile}" "${keyFile}" > "${trustedCertFile}"
  #
  #   # Cleanup temporary CSR file
  #   rm "${domain}.csr"
  #
  #   echo "SSL certificate, private key, and trusted certificate generated successfully:"
  #   echo "Certificate: ${certFile}"
  #   echo "Private Key: ${keyFile}"
  #   echo "Trusted Certificate: ${trustedCertFile}"
  # '';

  buildPhase = ''
    export CAROOT="$TMPDIR/mkcert"
    mkdir -p "$CAROOT"
    cd "$CAROOT"
    PATH="${pkgs.nssTools}/bin:$PATH" ${pkgs.mkcert}/bin/mkcert -install
    ${pkgs.mkcert}/bin/mkcert ${domain}
  '';

  installPhase = ''
    export CAROOT="$TMPDIR/mkcert"
    ls
    ls $CAROOT
    mkdir $out
    cp -r $CAROOT $out
    # cp ${certFile} $out
    # cp ${keyFile} $out
    # cp ${trustedCertFile} $out
  '';

  nativeBuildInputs = [ pkgs.openssl ];
}
