CHAPTERS=$(patsubst source/%,%,$(wildcard source/chapter*.md))

all: $(CHAPTERS)

docker:
	docker build -t learn-git-generate ./docker

chapter0.md: source/chapter0.md
chapter1.md: source/chapter1.md
chapter2.md: source/chapter1.md source/chapter2.md
chapter3.md: source/chapter3.md
chapter4.md: source/chapter4.md
chapter5.md: source/chapter5.md
chapter6.md: source/chapter6.md
chapter7.md: source/chapter7.md
chapter8.md: source/chapter7.md source/chapter8.md
chapter9.md: source/chapter9.md
chapter10.md: source/chapter10.md
chapter11.md: source/chapter11.md
chapter12.md: source/chapter12.md
chapter13.md: source/chapter6.md source/chapter13.md
chapter14.md: source/chapter1.md source/chapter14.md

$(CHAPTERS): generate
	./$^ >$@

clean:
	rm -f ./chapter*.md

.PHONY: all docker clean

.DELETE_ON_ERROR: $(CHAPTERS)
