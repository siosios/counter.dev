
alpineversion = edge

.DEFAULT_GOAL := all

include .config/makefile*.env
export


.PHONY: devserver
devserver:
	make buildlocal
	PLASH_EXPORT=WEBSTATS_MAILGUN_SECRET_API_KEY . .config/dev.sh && exec ./webstats

.PHONY: tests
tests:
	. .config/test.sh && go test

.PHONY: format
format:
	plash --from alpine:$(alpineversion) --apk npm --run 'npm i prettier --global' -- prettier --html-whitespace-sensitivity ignore --write .
	find -type f -name \*.go | xargs -L1 go fmt

.PHONY: logs
logs:
	ssh root@172.104.148.60 cat log

.PHONY: logs
get-newsletter-subscriptions:
	ssh root@172.104.148.60 scripts/get-newsletter-subscriptions

.PHONY: chgprodpwd
chgprodpwd:
	ssh root@172.104.148.60 ''. .config/production.sh && python3 scripts/chgpwd.py $(user) $(password)


.PHONY: chglocalpwd
chglocalpwd:
	. .config/.sh && python3 scripts/chgpwd.py $(user) $(password)

.PHONY: build
build:
	./scripts/build


.PHONY: buildlocal
buildlocal:
	cd backend && go build -o ../webstats

.PHONY: deploy
deploy:
	make build
	rsync .config webstats scripts root@172.104.148.60: -av
	ssh root@172.104.148.60 "pkill -x dtach; sleep 5; dtach -n /tmp/dtach ./scripts/prodrun"

.PHONY: redis-server
redis-server:
	scp root@172.104.148.60:/var/lib/redis/dump.rdb /tmp/webstats-production.rdb
	plash --from alpine:$(alpineversion) --apk redis -- redis-server --dbfilename webstats-production.rdb --dir /tmp

.PHONY: log
log:
	ssh root@172.104.148.60 tail log

.PHONY: integrations
integrations:
	ssh root@172.104.148.60 python3 scripts/integrations.py


out/blog: templates/blog/* $(shell find content/posts)
	mkdir -p out/blog
	cd .pelican && pelican content
	touch out/blog # mark as done


out/pages/%.html: content/pages/%.md templates/pages.html
	yasha -o $@  --file $< --extensions templates/ext.py templates/pages.html

out/help/%.html: content/help/%.md templates/ext.py templates/help.html
	yasha -o $@ --file $< --extensions templates/ext.py templates/help.html


HELP_MD_FILES := $(wildcard content/help/*.md)
HELP_HTML_FILES := $(patsubst content/help/%.md,out/help/%.html,$(HELP_MD_FILES))

PAGES_MD_FILES := $(wildcard content/pages/*.md)
PAGES_HTML_FILES := $(patsubst content/pages/%.md,out/pages/%.html,$(PAGES_MD_FILES))

all: out/pages out/help out/blog  $(HELP_HTML_FILES) $(PAGES_HTML_FILES)


.PHONY: clean
clean:
	rm -rf out

out/pages:
	mkdir -p out/pages

out/help:
	mkdir -p out/help

download-archives:
	ssh root@172.104.148.60 cp /state/db/archive.db /tmp/archive.db
	scp root@172.104.148.60:/tmp/archive.db /tmp/archive.db


# Snippset needed when setting counter.dev up in new servers
#provision:
#	ssh root@172.104.148.60 sh -c ' \
#	for i in `curl https://www.cloudflare.com/ips-v4`; do iptables -I INPUT -p tcp -m multiport --dports http,https -s $i -j ACCEPT; done \
#	for i in `curl https://www.cloudflare.com/ips-v6`; do ip6tables -I INPUT -p tcp -m multiport --dports http,https -s $i -j ACCEPT; done \
#	iptables -A INPUT -p tcp -m multiport --dports http,https -j DROP \
#	ip6tables -A INPUT -p tcp -m multiport --dports http,https -j DROP \
#	'
#
