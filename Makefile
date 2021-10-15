DIRECTORY := $(shell cat info.json | jq '.title')_$(shell cat info.json | jq '.version')
NAME := $(DIRECTORY).zip

all:
	rm -rf $(NAME)
	mkdir $(DIRECTORY)
	cp *.lua $(DIRECTORY)
	cp *.json $(DIRECTORY)
	cp LICENSE $(DIRECTORY)
	zip -9qr $(NAME) ./$(DIRECTORY)
	rm -rf $(DIRECTORY)
