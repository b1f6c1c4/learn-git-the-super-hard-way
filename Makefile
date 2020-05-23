CHAPTERS=$(patsubst source/%,%,$(wildcard source/chapter*.md))
TESTS=$(wildcard test/*.src.md)
REPORTS=$(patsubst %.src.md,%.output.md,$(TESTS))

all: $(CHAPTERS) test

test: $(REPORTS)

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
chapter15.md: source/chapter15.md

$(CHAPTERS): generate
	./$^ >$@

test/%.output.md: generate test/%.src.md test/%.dst.md
	./$< $(word 2,$^) >$@
	cmp --silent $@ $(word 3,$^)

clean:
	rm -f ./chapter*.md ./test/*.output.md

.PHONY: all docker clean test

.DELETE_ON_ERROR: $(CHAPTERS) $(REPORTS)
