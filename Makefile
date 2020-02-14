.PHONY: all docker

all: chapter0.md

docker:
	docker build -t learn-git-generate ./docker

chapter0.md: source/chapter0.md
	./generate $^ >$@ || rm -f $@
