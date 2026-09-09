# Variables
ROOT_CERT_NAME = rootCA

WILDCARD_DOMAIN = *.$(BASE_DOMAIN)
BASE_PATH = certs
DAYS = 3650  # 10 ans pour le certificat racine
OPENSSL = openssl

WILDCARD = $(BASE_PATH)/_wildcard.$(BASE_DOMAIN)
LDAP = $(BASE_PATH)/ldap.$(BASE_DOMAIN)
HOME_CA = $(BASE_PATH)/homeCA

# install :  trust anchor --store certs/homeCA.pem


all:  $(BASE_PATH) $(HOME_CA).crt $(WILDCARD).key $(LDAP).key $(HOME_CA).p12

$(HOME_CA).key:
	PASS=$(OPENSSL rand -base64 64)
	$(OPENSSL) genrsa -aes256 -out "$(HOME_CA).key" -passout "pass:$(PASS)" 4096
	$(OPENSSL) rsa -in "$(HOME_CA).key" -out "$(HOME_CA).key" -passin "pass:$(PASS)"
	chown nginx  $(HOME_CA).key


$(HOME_CA).pem: $(HOME_CA).key
	$(OPENSSL) req -x509 -new -days 3650 -key "$(HOME_CA).key" -out "$(HOME_CA).pem" -subj "/C=FR/ST=Alsace/L=Strasbourg/O=Nas/OU=Grouper/CN=$(BASE_DOMAIN)"

$(HOME_CA).crt: $(HOME_CA).pem
	$(OPENSSL) x509 -in $(HOME_CA).pem -inform PEM -out $(HOME_CA).crt
	chown nginx  $(HOME_CA).crt


$(WILDCARD).key: $(HOME_CA).crt $(HOME_CA).key
	openssl genrsa -out $(WILDCARD).key 4096
	openssl req -new -key $(WILDCARD).key -out $(WILDCARD).csr -subj "/C=FR/ST=Alsace/L=Strasbourg/O=Nas/OU=Grouper/CN=*.$(BASE_DOMAIN)" -addext "subjectAltName=DNS:*.$(BASE_DOMAIN),DNS:$(BASE_DOMAIN)"
	openssl x509 -req -in $(WILDCARD).csr -CA $(HOME_CA).crt -CAkey $(HOME_CA).key -CAcreateserial -out $(WILDCARD).crt -days 500 -sha256 -copy_extensions copy
	chown nginx $(WILDCARD).key $(WILDCARD).crt

$(LDAP).key: $(HOME_CA).crt $(HOME_CA).key
	openssl genrsa -out $(LDAP).key 4096
	openssl req -new -key $(LDAP).key -out $(LDAP).csr -subj "/C=FR/ST=Alsace/L=Strasbourg/O=Nas/OU=Grouper/CN=ldap.$(BASE_DOMAIN)" -addext "subjectAltName=DNS:ldap.$(BASE_DOMAIN)"
	openssl x509 -req -in $(LDAP).csr -CA $(HOME_CA).crt -CAkey $(HOME_CA).key -CAcreateserial -out $(LDAP).crt -days 500 -sha256 -copy_extensions copy
	chown openldap:openldap $(LDAP).key $(LDAP).crt

%.p12: %.key $(HOME_CA).crt
	openssl pkcs12 -export -out $@ -inkey $*.key -in $*.crt -certfile $(HOME_CA).crt -passout pass:
	chmod 600 $@

$(BASE_PATH):
	mkdir -p $(BASE_PATH) 

clean:
	rm -rf $(WILDCARD)*
	rm -rf $(LDAP)*

clean-all:
	rm -rf $(BASE_PATH)/

.PHONY: all clean 
