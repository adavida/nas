# Variables
ROOT_CERT_NAME = rootCA
BASE_DOMAIN=nas-test.local
WILDCARD_DOMAIN = *.$(BASE_DOMAIN)
BASE_PATH = certs
DAYS = 3650  # 10 ans pour le certificat racine
OPENSSL = openssl

WILDCARD = $(BASE_PATH)/_wildcard.$(BASE_DOMAIN)
LDAP = $(BASE_PATH)/ldap.$(BASE_DOMAIN)
HOME_CA = $(BASE_PATH)/homeCA

# install :  trust anchor --store certs/homeCA.pem


all:  $(BASE_PATH) $(HOME_CA).crt $(WILDCARD).key $(LDAP).key

$(HOME_CA).key:
	PASS=$(OPENSSL rand -base64 64)
	$(OPENSSL) genrsa -aes256 -out "$(HOME_CA).key" -passout "pass:$(PASS)" 4096
	$(OPENSSL) rsa -in "$(HOME_CA).key" -out "$(HOME_CA).key" -passin "pass:$(PASS)"

$(HOME_CA).pem: $(HOME_CA).key
	$(OPENSSL) req -x509 -new -days 3650 -key "$(HOME_CA).key" -out "$(HOME_CA).pem" -subj "/C=FR/ST=Alsace/L=Strasbourg/O=Nas/OU=Grouper/CN=nas.local"

$(HOME_CA).crt: $(HOME_CA).pem
	$(OPENSSL) x509 -in $(HOME_CA).pem -inform PEM -out $(HOME_CA).crt


$(WILDCARD).key: $(HOME_CA).crt $(HOME_CA).key
	openssl genrsa -out $(WILDCARD).key 4096
	openssl req -new -key $(WILDCARD).key -out $(WILDCARD).csr -subj "/C=FR/ST=Alsace/L=Strasbourg/O=Nas/OU=Grouper/CN=*.nas.local"
	openssl x509 -req -in $(WILDCARD).csr -CA $(HOME_CA).crt -CAkey $(HOME_CA).key -CAcreateserial -out $(WILDCARD).crt -days 500 -sha256

$(LDAP).key: $(HOME_CA).crt $(HOME_CA).key
	openssl genrsa -out $(LDAP).key 4096
	openssl req -new -key $(LDAP).key -out $(LDAP).csr -subj "/C=FR/ST=Alsace/L=Strasbourg/O=Nas/OU=Grouper/CN=ldap.nas.local"
	openssl x509 -req -in $(LDAP).csr -CA $(HOME_CA).crt -CAkey $(HOME_CA).key -CAcreateserial -out $(LDAP).crt -days 500 -sha256
	chown openldap:openldap $(LDAP).key $(LDAP).crt

$(BASE_PATH):
	mkdir -p $(BASE_PATH) 

k8s: $(HOME_CA).pem $(WILDCARD).key
	kubectl create secret tls wildcard-tls-cert --key=$(WILDCARD).key --cert=$(WILDCARD).crt
	cp $(HOME_CA).pem rootCA.pem
	kubectl create configmap ca-pemstore --from-file=rootCA.pem

clean:
	rm -rf $(BASE_PATH)/*

clean-k8s:
	kubectl delete configmaps ca-pemstore
	kubectl delete secrets wildcard-tls-cert

.PHONY: all clean k8s
