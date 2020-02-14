.PHONY: all docker

all: chapter0.md chapter1.md chapter2.md

docker:
	docker build -t learn-git-generate ./docker

chapter0.md: source/chapter0.md
	./generate $^ >$@ || rm -f $@

chapter1.md: source/chapter1.md
	./generate $^ >$@ || rm -f $@

chapter2.md: source/chapter1.md source/chapter2.md
	./generate $^ >$@ || rm -f $@
