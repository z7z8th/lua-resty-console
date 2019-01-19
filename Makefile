DST_DIR = lua-resty-console
NGINX_PATH = /usr/local/opt/openresty/nginx/sbin:/usr/local/openresty/nginx/sbin:${PATH}
DOCKER_IMAGE = nickxiao/openresty-testsuite

all: lint test

lint:
	docker-compose run --rm app luacheck .

build_image:
	docker build -t ${DOCKER_IMAGE}:latest -f Dockfile .

push_image:
	docker push ${DOCKER_IMAGE}:latest

pull_image:
	docker pull ${DOCKER_IMAGE}:latest

test: test_openresty test_luajit_integrational

test_openresty:
	@echo OPENRESTY:
	@docker-compose run --rm app sh -c 'apk add perl && resty-busted spec'

test_luajit_integrational:
	@echo LUAJIT INTEGRATIONAL:
	@docker-compose run --rm app sh -c 'apk add expect readline && bin/test_with_expect'

shell:
	docker-compose run --rm app

sync:
	time (for d in expect/ spec/ .luacheckrc docker-compose.yml lib/ Makefile lua/ bin/ conf/; do rsync -rP $$d $(TARGET):$(DST_DIR)/$$d & done; wait)

run:
	PATH=$(NGINX_PATH) nginx -p ${PWD} -c conf/nginx.conf

kill:
	kill `cat logs/nginx.pid` || echo

log:
	tail -f logs/error.log


.PHONY: lint test shell repl build push_images test_openresty \
	test_luajit_integrational 
